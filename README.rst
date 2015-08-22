puppet-ltsp
===========

Introduction
------------

This Puppet module is a wrapper around Linux Terminal-Server Project scripts,
making it slightly easier to manage the Debian or Ubuntu based server.

.. code:: puppet

    ltsp::server { "192.168.0.": }
    ltsp::client { "i386": }
    ltsp::client { "armhf": }

Obviously you need to install your favourite desktop environment separately,
note that Ubuntu default desktop is too heavyweight for terminal-servers and
using traditional X11 desktops is recommended.

Note that Ubuntu 15.04 and 15.10 are pretty much broken for LTSP,
so picking Long-Term Support release such as 14.04 is recommended.

Terminal root filesystem is placed under /opt/ltsp/$ARCH, which
is then compressed to SquashFS image under /opt/ltsp/images and served
via NBD by default. When terminal boots the SquashFS image is mounted over
the network as read-only and read-write *tmpfs* layer is mounted on top of
that using either *aufs* and *overlayfs*.
For Ubuntu 14.04 you should stick with Ubuntu's default kernel
which ships with *aufs* patches or use 3.18+ kernel which
has mainlined support for *overlayfs*.
You may of course upgrade the kernel of server.


Testing with VirtualBox
-----------------------

Preferred way to test LTSP is using Ubuntu 14.04 LTS server install
in VirtualBox virtual machine.
Use internal network to set up second machine for PXE booting
and use USB forwarding to attach smartcard reader to the LTSP client.
Note that VirtualBox kernel modules work as expected only with Ubuntu
official kernels and attempting to compile VirtualBox modules for 3.18+
kernels is troublesome!


Testing with KVM
----------------

KVM is built-in functionality in Linux kernel.

Set up bridge for internal network:

.. code:: bash

    brctl addbr internal0

Create QEMU interface script for joining the machine to bridge
in ``/etc/qemu-tapup`` and make it executable:

.. code:: bash

    #!/bin/bash
    /sbin/ifconfig $1 0.0.0.0 promisc up
    /sbin/brctl addif internal0 $1

Create harddisk image for virtual machine:

.. code:: bash

    qemu-img create -f raw ltspserver.raw 20G

Start up virtual machine for server:

.. code:: bash

    kvm -cdrom ubuntu-14.04.3-server-amd64.iso \
      -drive file=ltsptrusty.raw,if=virtio -m 2048 -smp 4 \
      -netdev user,id=wan \
      -device virtio-net,netdev=wan \
      -netdev tap,id=lan0,script=/etc/qemu-tapup,mac=52:54:00:12:34:59 \
      -device virtio-net,netdev=lan

Use following to PXE boot terminal:

.. code:: bash

    kvm  -m 128 -smp 1 -boot n -vga qxl \
      -netdev tap,id=lan,script=/etc/qemu-tapup \
      -device virtio-net,netdev=lan,mac=52:54:00:12:34:58 \
      -usb -device usb-host,hostbus=1,hostaddr=4


Testing with containers
-----------------------

DO NOT attempt to use LXC and probably other container technologies to host
LTSP server, there are several issues with running
NFS and DHCP servers from containers.

