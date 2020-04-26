import os
import pytest
import subprocess
import testinfra

@pytest.fixture(scope='session')
def host(request):
    subprocess.check_call(["docker", "build", f"--build-arg=VERSION=v1.4.2", "-t", "image-under-test", "."])
    docker_id = subprocess.check_output(
        ['docker', 'run', '--rm', '-d', 'image-under-test']).decode().strip()

    yield testinfra.get_host("docker://" + docker_id)

    # teardown
    subprocess.check_call(['docker', 'rm', '-f', docker_id])


def test_system(host):
    assert host.system_info.distribution == 'alpine'


def test_entrypoint(host):
    file = '/usr/local/bin/entrypoint.sh'
    assert host.file(file).exists
    assert host.file(file).user == 'syncthing'
    assert host.file(file).group == 'syncthing'


def test_version(host):
    assert "v1.4.2" in host.check_output("/usr/local/bin/syncthing --version")


def test_user(host):
    user = 'syncthing'
    assert host.user(user).uid == 770
    assert host.user(user).gid == 770
    assert host.user(user).shell == '/bin/false'


def test_user_is_locked(host):
    assert 'syncthing L ' in host.check_output('passwd --status syncthing')


def test_app(host):
    file = "/usr/local/bin/syncthing"
    assert host.file(file).exists
    assert host.file(file).user == 'syncthing'
    assert host.file(file).group == 'syncthing'


def test_upgrades_are_disabled(host):
    assert host.check_output('echo $STNOUPGRADE') == '1'


@pytest.mark.parametrize('package', [
    ('curl'),
    ('shadow'),
    ('su-exec'),
])
def test_installed_dependencies(host, package):
    assert host.package(package).is_installed
