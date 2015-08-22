define ltsp::server (
    $subnet = $title,
    $headless = true,
    $nbd = true,
    $nfs = false,
    $dhcp = false
) {

    if ! defined( Package["qemu-user-static"] ) {
        package { "qemu-user-static":
           ensure => installed
        }
    }

    if ! defined( Package["binfmt-support"] ) {
        package { "binfmt-support":
           ensure => installed
        }
    }

    package { "tftpd-hpa":
        ensure => installed
    }
    ->
    file_line { "tftpd-address":
        path => "/etc/default/tftpd-hpa",
        match => "TFTP_ADDRESS=\"[::]:69\"",
        line => "TFTP_ADDRESS=\":69\""
    }
    ->
    Package["ltsp-server"]


    # Debian assumes /opt/ltsp is present in /etc/exports
    package { "nfs-kernel-server":
        ensure => $nfs ? { true => installed, false => absent }
    }
    ->
    file { "/etc/exports":
        ensure => present,
        mode => 0644,
        owner => root,
        group => root
    }
    ->
    file_line { "nfs-server-ltsp-export":
        ensure => $nfs ? { true => present, false => absent },
        path => "/etc/exports",
        line => "/opt/ltsp $subnet0/24(ro,no_root_squash,async,no_subtree_check)",
        match => "/opt/ltsp "
    }
    ->
    # Estonian ID-card enabling patches
    apt::source { "koodur-ltsp":
        location => "http://packages.koodur.com",
        release => $lsbdistcodename,
        repos => "ltsp",
        key => "469F3592B88F65E22E3CDC1D391D5FD6B8A6153D",
        key_source => "http://packages.koodur.com/keyring.gpg",
        include_src => false
    }
    ->
    package { "openssh-server":
        ensure => "1:6.7p1-6ubuntu1koodur0"
    }
    ->
    file_line { "stream-local-bind-unlink":
        path => "/etc/ssh/sshd_config",
        match => "StreamLocalBindUnlink ",
        line => "StreamLocalBindUnlink yes"
    }
    ->
    Package["qemu-user-static"]
    ->
    Package["binfmt-support"]
    ->
    package { "ltsp-server":
        ensure => installed
    }
    ->
    package { "ltsp-server-standalone":
        ensure => absent
    }
    ->
    file { "/etc/X11/Xsession.d/80-pcsclite":
        ensure => present,
        mode => 644,
        owner => root,
        group => root,
        content => "export PCSCLITE_CSOCK_NAME=\$HOME/.pcscd.comm"
    }
    ->
    file { "/etc/ltsp/nbd-server.allow":
        ensure => absent, # nbd-server broken!
        mode => 755,
        owner => root,
        group => root,
        content => "$subnet0/24\n"
    }
    ->
    package { "nbd-server":
        ensure => $nbd ? { true => installed, false => absent }
    }
    ->
    # For mounting memory sticks to server
    package { "ltspfs":
        ensure => installed
    }
    ->
    # Session and locale listing for terminals
    package { "ldm-server":
        ensure => installed
    }

    # Disable lightdm for server
    service { "lightdm":
        ensure => $headless ? { true => stopped, false => running },
        enable => ! $headless
    }

    service { "nfs-kernel-server":
        ensure => $nfs ? { true => running, false => stopped },
        enable => $nfs,
        subscribe => [File_line["nfs-server-ltsp-export"], Package["nfs-kernel-server"]]
    }

    service { "nbd-server":
        enable => $nbd,
        subscribe => Package["nbd-server"]
    }
}
