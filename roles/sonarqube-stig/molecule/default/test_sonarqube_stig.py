def test_os_release_exists(host):
    f = host.file("/etc/os-release")
    assert f.exists
