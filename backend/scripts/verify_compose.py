"""Check built Compose images on a new isolated project/database through the frontend proxy.

Requires Docker Compose, Python 3 and Node.js 22+. Run after docker compose up -d --build.
Never imports fixtures into the normal database. Removes only this invocation's containers
and network; keeps its uniquely named PostgreSQL volume (no down -v).
"""
import argparse
import base64
from http.client import HTTPException
import json
import os
from pathlib import Path
import secrets
import socket
import ssl
import subprocess
import time
from urllib.error import URLError
from urllib.request import urlopen
import uuid
from question_image_fixtures import illustrated_fixture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backend-image', help='Optional freshly built image to check without restarting the main backend')
    parser.add_argument('--frontend-image', help='Optional freshly built proxy image to check without restarting the main frontend')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    cache = root / 'backend/.cache'
    cache.mkdir(exist_ok=True)
    project = 'skillbattles-compose-check-' + uuid.uuid4().hex[:10]
    env = os.environ.copy()
    for key in list(env):
        if key.startswith(('POSTGRES_', 'DB_', 'JWT_', 'STRIPE_', 'BILLING_', 'SMTP_', 'PASSWORD_RESET_')) or key in ('MAIL_FROM', 'NODE_OPTIONS', 'NODE_EXTRA_CA_CERTS', 'NODE_TLS_REJECT_UNAUTHORIZED'):
            env.pop(key)
    # Shell environment overrides root .env only for this child Compose project.
    # Docker reassigns published port 0 on restart. Pick distinct free host ports
    # so the runner and browser keep the same origin across the restart check.
    reservations = [socket.socket() for _ in range(4)]
    for reservation in reservations:
        reservation.bind(('127.0.0.1', 0))
    ports = [str(reservation.getsockname()[1]) for reservation in reservations]
    for reservation in reservations:
        reservation.close()
    env.update(POSTGRES_DB='compose_check', POSTGRES_USER='compose_check',
               POSTGRES_PASSWORD=secrets.token_hex(24), JWT_SECRET=base64.b64encode(secrets.token_bytes(32)).decode(),
               POSTGRES_PORT=ports[0], BACKEND_PORT=ports[1], FRONTEND_PORT=ports[2], FRONTEND_HTTPS_PORT=ports[3],
               COUNTDOWN_SECONDS='1', REVEAL_SECONDS='1',
               STRIPE_SECRET_KEY='', STRIPE_WEBHOOK_SECRET='', STRIPE_PRICE_PRO_MONTHLY='', STRIPE_PRICE_PRO_ANNUAL='',
               BILLING_SUCCESS_URL='', BILLING_CANCEL_URL='', BILLING_PORTAL_RETURN_URL='',
               SMTP_HOST='', SMTP_USERNAME='', SMTP_PASSWORD='', MAIL_FROM='', PASSWORD_RESET_BASE_URL='')
    ca_file = root / 'backend/.cache/local-tls/ca.crt'
    if not ca_file.is_file():
        parser.error('Initialize local HTTPS certificates first: backend/scripts/Initialize-LocalHttps.ps1')
    tls = ssl.create_default_context(cafile=str(ca_file))
    env['NODE_EXTRA_CA_CERTS'] = str(ca_file)
    hidden = {'creationflags': subprocess.CREATE_NO_WINDOW} if os.name == 'nt' else {}

    def run(parts, **kwargs):
        return subprocess.check_output(parts, cwd=root, env=env, text=True, stderr=subprocess.STDOUT, **hidden, **kwargs).strip()

    # Resolve the actual images built by the main project without reading/printing ENV.
    images = {
        'backend': run(['docker', 'image', 'inspect', '--format', '{{.Id}}', args.backend_image])
                   if args.backend_image else run(['docker', 'compose', 'images', '-q', 'backend']),
        'frontend': run(['docker', 'image', 'inspect', '--format', '{{.Id}}', args.frontend_image])
                    if args.frontend_image else run(['docker', 'compose', 'images', '-q', 'frontend']),
    }
    if not all(images.values()):
        parser.error('Build/start the root Compose project first.')
    override = cache / (project + '.json')
    override.write_text(json.dumps({'services': {s: {'image': image} for s, image in images.items()}}), encoding='utf-8')
    compose = ['docker', 'compose', '-p', project, '-f', str(root / 'compose.yml'), '-f', str(override)]
    revision = cache / (project + '-revision.json')
    revision.write_text('[]', encoding='utf-8')
    log = (cache / (project + '.log')).open('w', encoding='utf-8')
    runner = None
    created = False

    def command(*parts):
        return run(compose + list(parts))

    def wait_ready():
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            try:
                with urlopen(base + '/v3/api-docs', timeout=2, context=tls) as response:
                    if response.status == 200:
                        return
            except (URLError, OSError, HTTPException):
                pass
            time.sleep(.5)
        raise RuntimeError('Compose proxy readiness timeout; inspect ' + str(log.name))

    def import_questions(path, apply):
        container = command('ps', '-q', 'backend')
        run(['docker', 'cp', str(path), container + ':/tmp/compose-questions.json'])
        subprocess.run(compose + ['exec', '-T', 'backend', 'java', '-Duser.timezone=UTC', '-jar', 'app.jar',
                       '--spring.profiles.active=question-import', '--questions.file=/tmp/compose-questions.json',
                       '--questions.apply=' + str(apply).lower()], cwd=root, env=env, check=True,
                       stdout=log, stderr=subprocess.STDOUT, timeout=60, **hidden)

    try:
        created = True
        subprocess.run(compose + ['up', '-d', '--no-build', '--wait', '--wait-timeout', '120'], cwd=root, env=env,
                       check=True, stdout=log, stderr=subprocess.STDOUT, timeout=150, **hidden)
        port = command('port', 'frontend', '8443').rsplit(':', 1)[1]
        base = 'https://127.0.0.1:' + port
        wait_ready()
        assert command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                       "select max(version::int) from flyway_schema_history where success") == '14'
        assert command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                       "select count(*) from flyway_schema_history where success and type='SQL'") == '14'
        assert command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                       'select count(*) from questions where active and not deleted') == '239'
        fixture = illustrated_fixture(root / 'backend', cache / (project + '-fixture.json'))
        import_questions(fixture, False)
        assert command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                       'select count(*) from questions') == '261'
        # Only this new test project's DB is changed. Keep all seeded rows but
        # activate only the deterministic fixture for the gameplay assertions.
        command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                'update questions set active=false')
        import_questions(fixture, True)
        assert command('exec', '-T', 'postgres', 'psql', '-U', 'compose_check', '-d', 'compose_check', '-Atc',
                       'select count(*) from questions where active') == str(len(json.loads(fixture.read_text(encoding='utf-8'))))
        env.update(SKILLBATTLES_E2E_BASE_URL=base, SKILLBATTLES_E2E_FIXTURE=str(fixture), SKILLBATTLES_E2E_REVISION=str(revision))
        runner = subprocess.Popen(['node', str(root / 'backend/scripts/smoke_e2e.mjs')], cwd=root, env=env,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  text=True, encoding='utf-8', **hidden)
        restarted = False
        for line in runner.stdout:
            if line.strip() == 'REVISE_AND_RESTART':
                import_questions(revision, True)
                # Recreate the whole isolated stack on the same volume: no runtime
                # copies or writable container files may be needed for media recovery.
                log.write(command('up', '-d', '--no-build', '--force-recreate', '--wait', '--wait-timeout', '120'))
                wait_ready()
                runner.stdin.write('RESTARTED\n')
                runner.stdin.flush()
                restarted = True
            else:
                print(line.rstrip(), flush=True)
        if runner.wait(timeout=15) != 0 or not restarted:
            raise RuntimeError('Compose REST/STOMP check failed')
        print('Compose check passed: clean V1-V14, 239 active/261 stored seed revisions, fixture dry/apply, images and REST/STOMP through HTTPS proxy, whole-stack recreate with retained data.', flush=True)
    finally:
        if runner and runner.poll() is None:
            runner.terminate()
            runner.wait(timeout=10)
        if created:
            log.write(command('logs', '--no-color'))
            log.write(command('down'))  # Keep named volume; never touch normal project resources.
        log.close()
        revision.unlink(missing_ok=True)
        (cache / (project + '-fixture.json')).unlink(missing_ok=True)
        override.unlink(missing_ok=True)
        print('Test PostgreSQL volume retained: ' + project + '_postgres_data', flush=True)


if __name__ == '__main__':
    main()
