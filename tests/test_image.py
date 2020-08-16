import os
import pytest
import subprocess
import testinfra


@pytest.fixture(scope='session')
def host(request):
    # set the working directory to where the Dockerfile lives
    path = os.path.dirname(os.path.abspath(__file__)) + "/../"

    subprocess.check_call(['docker', 'build', '-t', 'syncthing', '.'], cwd=path)
    container = subprocess.check_output( ['docker', 'run', '--rm', '-d', 'syncthing'], cwd=path).decode().strip()

    yield testinfra.get_host("docker://" + container)

    subprocess.check_call(['docker', 'rm', '-f', container])


def test_system(host):
    assert host.system_info.distribution == 'alpine'
    assert host.system_info.release.startswith('3.')


def test_entrypoint(host):
    file = '/usr/bin/entrypoint.sh'
    assert host.file(file).exists
    assert host.file(file).user == 'syncthing'
    assert host.file(file).group == 'syncthing'
    assert oct(host.file(file).mode) == '0o550'


def test_process(host):
    assert host.file('/proc/1/cmdline').content_string.replace('\x00',
                                                               '') == '/usr/bin/syncthing-home=/config-no-browser'


def test_user(host):
    user = 'syncthing'
    assert host.user(user).uid == 770
    assert host.user(user).gid == 770
    assert host.user(user).shell == '/bin/false'


def test_user_is_locked(host):
    assert 'syncthing L ' in host.check_output('passwd --status syncthing')


def test_app(host):
    file = '/usr/bin/syncthing'
    assert host.file(file).exists
    assert host.file(file).user == 'syncthing'
    assert host.file(file).group == 'syncthing'
    assert oct(host.file(file).mode) == '0o550'


def test_upgrades_are_disabled(host):
    assert host.check_output('echo $STNOUPGRADE') == '1'


@pytest.mark.parametrize('package', [
    ('curl'),
    ('shadow'),
    ('su-exec'),
])
def test_installed_dependencies(host, package):
    assert host.package(package).is_installed
