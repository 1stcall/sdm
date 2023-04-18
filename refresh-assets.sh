#!/usr/bin/env bash
#
set -x
#
awk 'NR > 3' /etc/fstab | tee ./assets/my-fstab
cp -av ~/.bash{rc,_aliases} ./assets/
cp -av /etc/apt/sources.list.d/* ./assets/
cp -av /etc/apt/preferences.d/50-*-backports ./assets/
cp -av /etc/systemd/system/bluetooth.service.d/override.conf ./assets/bluetooth-override.conf
cp -av /etc/iptables/rules.v{4,6} ./assets/
cp -av /etc/systemd/system/nfs-blkmap.service.d/override.conf ./assets/nfs-blkmap-override.conf
cp -av /etc/systemd/system/dnsmasq.service.d/override.conf ./assets/dnsmasq-override.conf
cp -av /etc/systemd/system/nfs-blkmap.service.d/override.conf ./assets/nfs-blkmap-override.conf
cp -av /etc/dnsmasq.conf ./assets/
