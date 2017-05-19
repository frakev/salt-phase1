#!/usr/bin/env bash

PHASE1_IP="10.68.0.3/19"
NS1="10.68.1.109"
VRACKIF="eth1"

/bin/cat >>/root/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBMSpNq8/RI+E0NOGxGtRGCn7V99NZ5t7W58PaA3QWpP7EwVS0RexN2KSi6fteeKdbTUHBKLBzH0KjRqM0lEPMUx4j0W6jM75L6x9pGzLDuwc0zkl4bOOcmzf11lt97uRjQLjgx+0yZtBaUEmlcLGxPQwEBFbhE1lNedDkOFwZvLbkUfIi9ZzHMbIZcNReLU2DOhpueeBwZataSBD0D1gFegTJdjlP9o1mnm1k98uZK7CiLs3RnsBaRbP5P7wRyfgen8fzlxEAGmTWXgpqMGglQOHcd6LeWN67jTAeL21nkYSy5d3HvaLsm6J9CcrATKaayJixWLcon1Nz7rRUxAID
EOF

/sbin/ifconfig $VRACKIF up

/bin/ip addr add $PHASE1_IP dev $VRACKIF

/bin/ip route add 10.0.0.0/8 via 10.68.15.1 dev $VRACKIF

MYIP=`/usr/bin/host $HOSTNAME $NS1 | awk '{print $4}'|tail -n 1`

/bin/cat >/etc/network/interfaces.d/${VRACKIF}<<EOF
auto ${VRACKIF}
iface ${VRACKIF} inet static
	address ${MYIP}
	netmask 255.255.224.0
	network 10.68.0.0
	broadcast 10.68.31.255
	gateway 10.68.15.1
EOF

sed -i 's/^auto eth0$/#auto eth0/' /etc/network/interfaces

/bin/ip addr del $PHASE1_IP dev $VRACKIF
/sbin/ifdown eth1
/sbin/ifup eth1

/bin/cat >/etc/resolv.conf<<EOF
search rbx.twenga.lan twenga.lan
options attempts:5 timeout:1 ndots:3
nameserver 10.68.1.109
nameserver 10.68.1.114
nameserver 10.68.1.91
EOF

/bin/umount /srv

sed -i 's/^\/dev\/vg\/lv.*$//' /etc/fstab

/sbin/lvremove -f /dev/mapper/vg-lv
/sbin/vgremove -f vg
/sbin/pvremove -f /dev/md4

/usr/bin/apt update -q
/usr/bin/apt install -q -y linux-image-4.9.0-0.bpo.2-amd64 linux-base=4.3~bpo8+1

/bin/ping -q -c 1 -t 1 10.68.15.1 2>&1 > /dev/null ; if [[ $? == 0 ]]; then ifdown $VRACKIF ; fi

echo "OK"

exit 0
