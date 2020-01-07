import os
import pytest
import subprocess
import testinfra


@pytest.fixture(scope='session')
def host(request):
    subprocess.check_call(['docker', 'build', '-t', 'image-under-test', '.'])
    docker_id = subprocess.check_output(
        ['docker', 'run', '--rm', '-d', 'image-under-test']).decode().strip()

    yield testinfra.get_host("docker://" + docker_id)

    # teardown
    subprocess.check_call(['docker', 'rm', '-f', docker_id])


def test_system(host):
    assert host.system_info.distribution == 'alpine'
    assert host.system_info.release.startswith('3.')


def test_entrypoint(host):
    entrypoint = '/usr/local/bin/entrypoint.sh'
    assert host.file(entrypoint).exists
    assert oct(host.file(entrypoint).mode) == '0o555'


def test_process(host):
    assert host.file('/proc/1/cmdline').content_string.replace('\x00',
                                                               '') == '/app/syncthing-home=/config-no-browser'


def test_version(host):
    assert os.environ.get('VERSION', '1.3.3') in host.check_output(
        "/app/syncthing --version")


def test_user(host):
    user = 'syncthing'
    assert host.user(user).uid == 770
    assert host.user(user).gid == 770
    assert host.user(user).shell == '/bin/false'


def test_user_is_locked(host):
    assert 'syncthing L ' in host.check_output('passwd --status syncthing')


def test_app_folder(host):
    folder = '/app'
    assert host.file(folder).exists
    assert host.file(folder).user == 'syncthing'
    assert host.file(folder).group == 'syncthing'
    assert oct(host.file(folder).mode) == '0o550'


def test_upgrades_are_disabled(host):
    assert host.check_output('echo $STNOUPGRADE') == '1'


@pytest.mark.parametrize('package', [
    ('curl'),
    ('shadow'),
    ('su-exec'),
])
def test_installed_dependencies(host, package):
    assert host.package(package).is_installed
