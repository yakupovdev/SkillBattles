"""Run an isolated, disposable backend demo check. Never connects to the user's DB.

Requires Java 21, Docker, Node.js 22+ and a previously built backend JAR.
Creates one uniquely named PostgreSQL container with tmpfs storage, without volumes. Imports only
the explicit test fixture, deactivates bundled bank rows only in this temporary DB,
runs public REST/STOMP flows, restarts the JAR on that same
temporary DB, then removes only processes/container created by this invocation.
Credentials and JWTs are never printed or written to the report.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import socket
import subprocess
import tempfile
import time
from urllib.error import URLError
from urllib.request import urlopen
import uuid
from question_image_fixtures import illustrated_fixture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jar', default='target/backend-0.0.1-SNAPSHOT.jar')
    args = parser.parse_args()
    backend = Path(__file__).resolve().parent.parent
    jar = (backend / args.jar).resolve()
    if not jar.is_file():
        parser.error('Build the JAR first: .\\mvnw.cmd -B -ntp verify')
    env = os.environ.copy()
    # Do not inherit a deployment datasource, external Spring config, Java agents,
    # or frame logging. Only this runner's freshly created database may be used.
    for key in list(env):
        upper = key.upper()
        if upper.startswith(('SPRING_', 'APP_', 'DB_', 'JWT_', 'LOGGING_', 'STRIPE_', 'BILLING_', 'SMTP_', 'PASSWORD_RESET_')) or upper in {
            'MAIL_FROM', 'JAVA_TOOL_OPTIONS', 'JDK_JAVA_OPTIONS', '_JAVA_OPTIONS', 'JAVA_OPTS', 'NODE_OPTIONS', 'NODE_USE_ENV_PROXY'
        }:
            env.pop(key)
    java = str(Path(env['JAVA_HOME']) / 'bin' / ('java.exe' if os.name == 'nt' else 'java')) if env.get('JAVA_HOME') else shutil.which('java')
    node, docker = shutil.which('node'), shutil.which('docker')
    if not java or not node or not docker:
        parser.error('Java 21, Node.js 22+ and Docker must be available.')
    version = subprocess.check_output([java, '-version'], env=env, stderr=subprocess.STDOUT, text=True)
    if not re.search(r'version "21[.\"]', version):
        parser.error('Use Java 21 via JAVA_HOME.')
    if int(subprocess.check_output([node, '--version'], env=env, text=True).strip().lstrip('v').split('.')[0]) < 22:
        parser.error('Node.js 22+ is required for native WebSocket.')
    subprocess.run([docker, 'info', '--format', '{{.ServerVersion}}'], env=env, check=True, stdout=subprocess.DEVNULL)

    name = 'skillbattles-e2e-' + uuid.uuid4().hex[:12]
    env['POSTGRES_PASSWORD'] = secrets.token_hex(24)
    env['JWT_SECRET'] = base64.b64encode(secrets.token_bytes(32)).decode()
    env['DB_USERNAME'] = 'e2e'
    env['DB_PASSWORD'] = env['POSTGRES_PASSWORD']
    # Explicitly remove deployment profiles; this is always an isolated local server.
    env.pop('SPRING_PROFILES_ACTIVE', None)
    target = backend / 'target'
    target.mkdir(exist_ok=True)
    temp = tempfile.NamedTemporaryFile(dir=target, prefix='e2e-revision-', suffix='.json', delete=False)
    revision = Path(temp.name).resolve()
    temp.close()
    process = runner = None
    logs = []
    created = False
    hidden = {'creationflags': subprocess.CREATE_NO_WINDOW} if os.name == 'nt' else {}

    def command(*parts):
        return subprocess.check_output([docker, *parts], env=env, text=True, stderr=subprocess.STDOUT).strip()

    def stop_backend():
        nonlocal process
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
        process = None

    def start_backend(label):
        nonlocal process
        output = (target / ('e2e-' + label + '.log')).open('w', encoding='utf-8')
        logs.append(output)
        process = subprocess.Popen([java, '-jar', str(jar), '--server.address=127.0.0.1', f'--server.port={port}',
                                    '--app.battle.countdown-seconds=1',
                                    '--app.battle.reveal-seconds=1'], cwd=backend, env=env, stdout=output, stderr=subprocess.STDOUT, **hidden)
        until = time.monotonic() + 40
        while time.monotonic() < until:
            if process.poll() is not None:
                raise RuntimeError('Backend exited during startup; inspect target/e2e-' + label + '.log')
            try:
                with urlopen(base + '/v3/api-docs', timeout=1) as response:
                    if response.status == 200:
                        return
            except (URLError, TimeoutError):
                pass
            time.sleep(.2)
        raise RuntimeError('Backend readiness timeout')

    def import_questions(path, apply, label):
        with (target / ('e2e-import-' + label + '.log')).open('w', encoding='utf-8') as output:
            subprocess.run([java, '-jar', str(jar), '--spring.profiles.active=question-import', '--questions.file=' + str(path),
                            '--questions.apply=' + str(apply).lower()], cwd=backend, env=env, stdout=output,
                           stderr=subprocess.STDOUT, check=True, timeout=40, **hidden)

    try:
        command('run', '--rm', '-d', '--name', name, '--tmpfs', '/var/lib/postgresql/data:rw,size=256m',
                '-e', 'POSTGRES_PASSWORD', '-e', 'POSTGRES_USER=e2e', '-e', 'POSTGRES_DB=e2e',
                '-p', '127.0.0.1::5432', 'postgres:17.12-alpine')
        created = True
        assert all(mount['Type'] != 'volume' for mount in json.loads(command('inspect', '--format', '{{json .Mounts}}', name)))
        until = time.monotonic() + 25
        while subprocess.run([docker, 'exec', name, 'pg_isready', '-U', 'e2e', '-d', 'e2e'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
            if time.monotonic() > until:
                raise RuntimeError('Temporary PostgreSQL readiness timeout')
            time.sleep(.2)
        pg_port = command('port', name, '5432/tcp').split(':')[-1]
        env['DB_URL'] = f'jdbc:postgresql://127.0.0.1:{pg_port}/e2e'
        with socket.socket() as available:
            available.bind(('127.0.0.1', 0))
            port = available.getsockname()[1]
        base = f'http://127.0.0.1:{port}'
        fixture = illustrated_fixture(backend, revision.with_name(revision.stem + '-fixture.json'))
        import_questions(fixture, False, 'dry')
        assert command('exec', name, 'psql', '-U', 'e2e', '-d', 'e2e', '-Atc', 'select count(*) from questions') == '261'
        command('exec', name, 'psql', '-U', 'e2e', '-d', 'e2e', '-Atc', 'update questions set active=false')
        import_questions(fixture, True, 'apply')
        assert command('exec', name, 'psql', '-U', 'e2e', '-d', 'e2e', '-Atc', 'select count(*) from questions where active') == str(len(json.loads(fixture.read_text(encoding='utf-8'))))
        start_backend('first')
        env.update(SKILLBATTLES_E2E_BASE_URL=base, SKILLBATTLES_E2E_FIXTURE=str(fixture), SKILLBATTLES_E2E_REVISION=str(revision))
        runner = subprocess.Popen([node, str(backend / 'scripts/smoke_e2e.mjs')], cwd=backend, env=env, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', **hidden)
        restarted = False
        for line in runner.stdout:
            if line.strip() == 'REVISE_AND_RESTART':
                import_questions(revision, True, 'revision')
                updated = json.loads(revision.read_text(encoding='utf-8'))[0]
                assert command('exec', name, 'psql', '-U', 'e2e', '-d', 'e2e', '-Atc',
                               "select count(*) from questions where active and external_key='" + updated['externalKey'].replace("'", "''") + "' and content_version=" + str(updated['contentVersion'])) == '1'
                stop_backend()
                start_backend('restart')
                runner.stdin.write('RESTARTED\n')
                runner.stdin.flush()
                restarted = True
            else:
                print(line.rstrip(), flush=True)
        runner_code = runner.wait(timeout=15)
        if runner_code != 0 or not restarted:
            raise RuntimeError(f'REST/STOMP end-to-end check failed (runner exit {runner_code}, restarted={restarted})')
        print('Isolated Java 21 JAR end-to-end check passed; only test fixtures were imported.', flush=True)
    finally:
        if runner is not None and runner.poll() is None:
            runner.terminate()
            try:
                runner.wait(timeout=5)
            except subprocess.TimeoutExpired:
                runner.kill()
                runner.wait()
        stop_backend()
        for output in logs:
            output.close()
        revision.unlink(missing_ok=True)  # Exact file created above; no directory/volume removal.
        revision.with_name(revision.stem + '-fixture.json').unlink(missing_ok=True)
        if created:
            subprocess.run([docker, 'rm', '-f', name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
