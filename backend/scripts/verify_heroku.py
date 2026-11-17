"""Verify the single Heroku image locally with 512 MiB, TLS Postgres and real REST/STOMP.

No Heroku commands, .env reads, user databases or named volumes. Requires Docker,
Node.js 22+ and OpenSSL (Windows Git OpenSSL is also detected). Run from repo root.
"""
import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen
import uuid
from question_image_fixtures import illustrated_fixture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', default='skillbattles-heroku-check')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    cache = root / 'backend/.cache'
    cache.mkdir(exist_ok=True)
    name = 'skillbattles-heroku-' + uuid.uuid4().hex[:10]
    pg, web = name + '-pg', name + '-web'
    files = cache / name
    files.mkdir()
    hidden = {'creationflags': subprocess.CREATE_NO_WINDOW} if os.name == 'nt' else {}
    env = {k: v for k, v in os.environ.items() if not k.upper().startswith(
        ('SPRING_', 'APP_', 'DB_', 'JWT_', 'STRIPE_', 'BILLING_', 'SMTP_', 'PASSWORD_RESET_', 'LOGGING_', 'NODE_'))
        and k.upper() not in ('DATABASE_URL', 'MAIL_FROM', 'JAVA_TOOL_OPTIONS', 'JDK_JAVA_OPTIONS', '_JAVA_OPTIONS')}
    env.update(POSTGRES_USER='heroku_check', POSTGRES_DB='heroku_check',
               POSTGRES_PASSWORD=secrets.token_hex(20) + ':@+/%',
               JWT_SECRET=base64.b64encode(secrets.token_bytes(32)).decode())
    env['DATABASE_URL'] = 'postgres://heroku_check:' + quote(env['POSTGRES_PASSWORD'], safe='') + '@' + pg + ':5432/heroku_check'
    env['SPRING_PROFILES_ACTIVE'] = 'heroku'
    openssl = shutil.which('openssl')
    if not openssl and Path('C:/Program Files/Git/usr/bin/openssl.exe').is_file():
        openssl = 'C:/Program Files/Git/usr/bin/openssl.exe'
    if not openssl:
        parser.error('OpenSSL is required to test DATABASE_URL with TLS.')
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0))
        port = reservation.getsockname()[1]
    env['PORT'] = str(port)
    base = 'http://127.0.0.1:' + str(port)
    report = {'image': args.image, 'memory_limit_mib': 512, 'container_port': port, 'start_seconds': []}
    created = []
    runner = None
    monitor_stop = threading.Event()
    peaks = []

    def command(*parts, child_env=None):
        result = subprocess.run(['docker', *parts], cwd=root, env=child_env or env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, **hidden)
        if result.returncode:
            # Docker errors may echo env arguments; avoid printing captured output.
            details = (result.stdout + result.stderr).replace(env['POSTGRES_PASSWORD'], '[REDACTED]')
            details = details.replace(env['DATABASE_URL'], '[REDACTED]')
            (files / 'operation-error.log').write_text(details, encoding='utf-8')
            raise RuntimeError('Docker operation failed: ' + parts[0])
        return result.stdout.strip()

    def sql(statement):
        return command('exec', pg, 'psql', '-U', 'heroku_check', '-d', 'heroku_check', '-Atc', statement)

    def http(path, status=200, headers=None):
        try:
            response = urlopen(Request(base + path, headers=headers or {}), timeout=10)
        except HTTPError as error:
            response = error
        assert response.status == status, (path, response.status)
        return response, response.read()

    def start():
        began = time.monotonic()
        command('start', web)
        while time.monotonic() - began < 60:
            if command('inspect', '--format', '{{.State.Running}}', web) != 'true':
                raise RuntimeError('Web exited; inspect the local check log.')
            try:
                # nginx binds before Java/Jaspr are ready; retry startup 502s.
                with urlopen(base + '/v3/api-docs', timeout=10) as response:
                    json.load(response)
                with urlopen(base + '/', timeout=10) as response:
                    assert b'<html' in response.read()
                elapsed = round(time.monotonic() - began, 2)
                report['start_seconds'].append(elapsed)
                print('Web ready including OpenAPI in ' + str(elapsed) + ' seconds.', flush=True)
                return
            except (URLError, OSError):
                time.sleep(.3)
        raise RuntimeError('Web did not become ready within the Cedar 60-second boot budget.')

    def sample():
        while not monitor_stop.is_set():
            try:
                result = command('exec', web, 'sh', '-c',
                                 'cat /sys/fs/cgroup/memory.current /sys/fs/cgroup/memory.peak; '
                                 'sed -n "/^VmRSS:/p" /proc/1/status').splitlines()
                peaks.append((int(result[0]), int(result[1]), int(result[2].split()[1]) * 1024))
            except (RuntimeError, ValueError, IndexError):
                pass
            monitor_stop.wait(2)

    try:
        subprocess.run([openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
                        '-keyout', str(files / 'server.key'), '-out', str(files / 'server.crt'),
                        '-subj', '/CN=' + pg], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, **hidden)
        command('network', 'create', name)
        created.append('network')
        command('create', '--name', pg, '--network', name, '--tmpfs', '/var/lib/postgresql/data:rw,size=256m',
                '-e', 'POSTGRES_USER', '-e', 'POSTGRES_PASSWORD', '-e', 'POSTGRES_DB',
                '--entrypoint', 'sh', 'postgres:17.12-alpine', '-c',
                'chown postgres:postgres /tmp/server.key /tmp/server.crt && chmod 600 /tmp/server.key && '
                'exec docker-entrypoint.sh postgres -c ssl=on -c ssl_cert_file=/tmp/server.crt -c ssl_key_file=/tmp/server.key')
        created.append(pg)
        command('cp', str(files / 'server.crt'), pg + ':/tmp/server.crt')
        command('cp', str(files / 'server.key'), pg + ':/tmp/server.key')
        command('start', pg)
        until = time.monotonic() + 30
        while time.monotonic() < until:
            try:
                if sql('select 1') == '1':
                    break
            except RuntimeError:
                time.sleep(.3)
        else:
            raise RuntimeError('Isolated PostgreSQL did not become ready.')
        command('create', '--name', web, '--network', name, '--memory', '512m', '--memory-swap', '512m',
                '-p', '127.0.0.1:' + str(port) + ':' + str(port),
                '-e', 'DATABASE_URL', '-e', 'JWT_SECRET', '-e', 'PORT', '-e', 'SPRING_PROFILES_ACTIVE',
                '-e', 'COUNTDOWN_SECONDS=1', '-e', 'REVEAL_SECONDS=1', args.image)
        created.append(web)
        start()
        assert sql('select count(*) from flyway_schema_history where success') == '14'
        assert sql('select max(version::int) from flyway_schema_history where success') == '15'
        assert sql('select count(*) from users') == '0'  # Test-only V13 is absent from the runtime JAR.
        assert sql('select count(*) from questions where active and not deleted') == '239'
        assert int(sql("select count(*) from pg_stat_ssl where ssl and pid in (select pid from pg_stat_activity where usename='heroku_check')")) > 0
        for route in ['/', '/auth', '/auth/forgot', '/auth/reset?token=not-a-secret', '/billing/return?success=true',
                      '/play/search', '/play/duel', '/profile', '/profile/edit', '/leaderboard', '/history', '/pro',
                      '/friends', '/friends/12345678-1234-1234-1234-123456789012',
                      '/battle/12345678-1234-1234-1234-123456789012', '/result/12345678-1234-1234-1234-123456789012']:
            response, body = http(route, headers={'X-Forwarded-Proto': 'https'})
            assert b'<html' in body and 'text/html' in response.headers['Content-Type']
            assert response.headers['Cross-Origin-Opener-Policy'] == 'same-origin'
            assert response.headers['Cross-Origin-Embedder-Policy'] == 'require-corp'
            assert 'no-store' in response.headers['Cache-Control']
        for asset, mime in [('/main.client.dart.js', 'javascript'), ('/styles/base.css', 'text/css'),
                            ('/vendor/katex/katex.min.js', 'javascript')]:
            response, body = http(asset)
            assert mime in response.headers['Content-Type'] and len(body) > 100
        for path in ['/assets/missing.js', '/missing.wasm']:
            response, body = http(path, 404)
            assert b'<html' not in body.lower() or b'404 Not Found' in body
        for path in ['/media/questions/missing.png']:
            response, body = http(path, 404)
            assert json.loads(body)['code'] == 'NOT_FOUND'
        response, body = http('/api/v1/users/me', 401)
        assert json.loads(body)['code'] == 'UNAUTHORIZED'
        suffix = uuid.uuid4().hex[:12]
        registration = Request(base + '/api/v1/auth/register', method='POST',
                               headers={'Content-Type': 'application/json'},
                               data=json.dumps({'birthYear': 2000, 'birthMonth': 1,
                                                'email': suffix + '@example.com', 'nickname': 'Check_' + suffix,
                                                'password': 'IsolatedCheck123!'}).encode())
        with urlopen(registration, timeout=10) as response:
            auth = json.load(response)
        response, body = http('/api/v1/missing', 404, headers={'Authorization': 'Bearer ' + auth['accessToken']})
        assert json.loads(body)['code'] == 'NOT_FOUND'
        http('/swagger-ui/missing.js', 404)
        http('/swagger-ui/index.html')
        subprocess.run(['python', str(root / 'backend/scripts/smoke_auth.py'), '--url', base],
                       cwd=root, env=env, check=True, timeout=45, **hidden)
        fixture = illustrated_fixture(root / 'backend', files / 'fixture.json')
        # Imports run with the web stopped so memory measurements reflect one JVM.
        command('stop', '--time', '20', web)
        importer_env = dict(env)
        importer_env['SPRING_PROFILES_ACTIVE'] = 'heroku,question-import'

        def import_stopped(path, apply):
            command('run', '--rm', '--network', name, '--memory', '512m',
                    '-e', 'DATABASE_URL', '-e', 'JWT_SECRET', '-e', 'PORT', '-e', 'SPRING_PROFILES_ACTIVE',
                    '--mount', 'type=bind,source=' + str(path) + ',target=/tmp/questions.json,readonly',
                    args.image, 'java', '-Xmx160m', '-jar', 'app.jar',
                    '--questions.file=/tmp/questions.json', '--questions.apply=' + str(apply).lower(), child_env=importer_env)

        import_stopped(fixture, False)
        assert sql('select count(*) from questions') == '261'
        sql('update questions set active=false')
        import_stopped(fixture, True)
        start()
        threading.Thread(target=sample, daemon=True).start()
        env.update(SKILLBATTLES_E2E_BASE_URL=base, SKILLBATTLES_E2E_FIXTURE=str(fixture),
                   SKILLBATTLES_E2E_REVISION=str(files / 'revision.json'))
        runner = subprocess.Popen(['node', str(root / 'backend/scripts/smoke_e2e.mjs')], cwd=root, env=env,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  text=True, encoding='utf-8', **hidden)
        restarted = False
        for line in runner.stdout:
            if line.strip() == 'REVISE_AND_RESTART':
                command('stop', '--time', '20', web)
                import_stopped(files / 'revision.json', True)
                start()
                runner.stdin.write('RESTARTED\n')
                runner.stdin.flush()
                restarted = True
            else:
                print(line.rstrip(), flush=True)
        assert runner.wait(timeout=20) == 0 and restarted, 'REST/STOMP runner failed'
        # Short HTTP load, on top of the preceding concurrent real gameplay sockets.
        began = time.monotonic()
        with ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(lambda _: http('/api/v1/subscriptions/plans'), range(240)))
        report['load'] = {'requests': 240, 'concurrency': 8, 'seconds': round(time.monotonic() - began, 2)}
        time.sleep(2)
        assert command('inspect', '--format', '{{.State.OOMKilled}}', web) == 'false'
        if peaks:
            report['sampled_supervisor_rss_peak_mib'] = round(max(p[2] for p in peaks) / 1048576, 1)
            report['cgroup_peak_mib'] = round(max(p[1] for p in peaks) / 1048576, 1)
            report['sampled_cgroup_peak_mib'] = round(max(p[0] for p in peaks) / 1048576, 1)
        report['tls_postgres'] = True
        report['checks'] = 'clean V1-V12,V14-V15; no demo users; Jaspr SSR/assets/MIME; JSON errors; auth; REST/STOMP; friends/images/stickers; retained DB/recovery; load'
        stop_began = time.monotonic()
        command('stop', '--time', '20', web)
        report['stop_seconds'] = round(time.monotonic() - stop_began, 2)
        report['exit_code'] = int(command('inspect', '--format', '{{.State.ExitCode}}', web))
        # HotSpot normally returns 128 + SIGTERM (143) after running shutdown hooks.
        assert report['exit_code'] in (0, 143)
        output = command('logs', web)
        assert 'Graceful shutdown complete' in output
        assert env['POSTGRES_PASSWORD'] not in output and env['DATABASE_URL'] not in output
        report['passed'] = True
        (cache / 'heroku-check-report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        print(json.dumps(report, indent=2), flush=True)
    finally:
        monitor_stop.set()
        report.setdefault('passed', False)
        (cache / 'heroku-check-report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        if runner and runner.poll() is None:
            runner.terminate()
            runner.wait(timeout=10)
        for container in reversed([c for c in created if c != 'network']):
            if container == web:
                try:
                    # Disposable logs only; redact even disposable datasource/user credentials.
                    output = command('logs', web).replace(env['POSTGRES_PASSWORD'], '[REDACTED]').replace(env['DATABASE_URL'], '[REDACTED]')
                    (files / 'web.log').write_text(output, encoding='utf-8')
                except RuntimeError:
                    pass
            command('rm', '-f', container)
        if 'network' in created:
            command('network', 'rm', name)
        (files / 'server.key').unlink(missing_ok=True)


if __name__ == '__main__':
    main()
