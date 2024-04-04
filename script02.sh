#!/usr/bin/env bash
# create a cloud-init config for container ubc
cat >cloud-init-ubc.yml <<EOF
#cloud-config
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
- mlocate
- wget

users:
- name: root
  ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDn/xarP47M2rz9UtE6jPQMMhBDJOKbWa1LJ/JRD6G6d3KNekq0rl65e7+0keIXrH7+rkVHn1jtqbHdXiDR1EngjcX1IAZyosmIqkTj9MAVTc+ZmoOLiJZYxCZ812Abnai/CM3Q77cQIFHUP/wb0fFdsGx9Szfobdb722K4jxvbyYwjMGJUHWmdFYpwPz7bqzX/s+3Ij9SPyQG9jT66tVmcIjiEloLgWF2DztT31OpvJHrtn/JuB8GDtNEsBezw+ga1ubUGjvCZ4z2iauB2kjesh2nhM0xpBDt9pthKGBoTr36gxJyhzUJk0pGbfJIkaxuf8mBnIxibR0+B1B8hT4GP tom
EOF

# create incus network profile we'll use for this ubc container
cat >ubcp-net-profile.yml <<EOF
devices:
  myport22:
    connect: tcp:127.0.0.1:22
    listen: tcp:0.0.0.0:2222
    type: proxy
  myport80:
    connect: tcp:127.0.0.1:80
    listen: tcp:0.0.0.0:80
    type: proxy
EOF

# delete old ubc container
incus ls --format=json | jq 'map(select(.name == "ubc")) | .[] | .name' | xargs --no-run-if-empty -I {} incus delete --force {}

# remove ubcp network profile if it exists
incus profile list --format=json | jq --raw-output 'map(select(.name == "ubcp") | .name) | .[]' | xargs --no-run-if-empty --max-args=1 incus profile delete

# create container profile ubcp
incus profile create ubcp
incus profile edit ubcp <ubcp-net-profile.yml

# create container named ubc that contains cloud-init
incus launch images:ubuntu/22.04/cloud ubc --config=user.user-data="$(cat cloud-init-ubc.yml)"

# assign profile ubcp to container ubc
incus profile add ubc ubcp
incus ls
