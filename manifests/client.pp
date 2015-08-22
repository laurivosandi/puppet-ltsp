define ltsp::client (
) {
    Package["ltsp-server"]
    ->
    exec { "ltsp-build-client-$title":
        command => "/usr/sbin/ltsp-build-client --extra-mirror 'http://packages.koodur.com trusty ltsp' --apt-keys /etc/apt/trusted.gpg --late-packages pcscd",
        environment => ["ARCH=$title", "LANG=C", "DEBOOTSTRAP=qemu-debootstrap"],
        creates => "/opt/ltsp/$title",
        timeout => 0
    }
    ->
    file { "/opt/ltsp/$title/etc/ssh/ssh_config":
        ensure => present,
        owner => root,
        group => root,
        mode => 644,
        content => "Host *\nSendEnv LANG LC_*\nRemoteForward ~/.pcscd.comm /run/pcscd/pcscd.comm\n"
    }
    ~>
    exec { "ltsp-update-image-$title":
        command => "/usr/sbin/ltsp-update-image $title",
        timeout => 0,
        refreshonly => true
    }
}
