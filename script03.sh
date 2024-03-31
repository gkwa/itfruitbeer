#!/usr/bin/env bash

# create cloud-init for container ubc
cat >cloud-init-ubc.yml<<EOF
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

runcmd:
- set -x
- set -e # this prevents script2 from running since script1 fails
- set -u
- bash -xe /root/script1.sh
- bash -xe /root/script2.sh

write_files:
- content: |
    #!/usr/bin/env bash

    set -x
    set -e
    set -u

    exit 1 # intentionally fail

  path: /root/script1.sh
  append: true
  permissions: "0755"

- content: |
    #!/usr/bin/env bash

    set -x
    set -e
    set -u

    touch /tmp/$(date +%s).txt

  path: /root/script2.sh
  append: true
  permissions: "0755"
EOF

# create lxc network profile we'll use for this ubc container
cat >ubcp-net-profile.yml<<EOF
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
lxc ls --format=json | jq 'map(select(.name == "ubc")) | .[] | .name' | xargs --no-run-if-empty -I {} lxc delete --force {}

# remove ubcp network profile if it exists
lxc profile list --format=json |
    jq --raw-output 'map(select(.name == "ubcp") | .name) | first // ""' |
    xargs --no-run-if-empty --max-args=1 lxc profile delete

# create container profile ubcp
lxc profile create ubcp
lxc profile edit ubcp < ubcp-net-profile.yml

# create container ubc
lxc launch ubuntu:22.04 ubc --config=user.user-data="$(cat cloud-init-ubc.yml)"

# assign profile ubcp to container ubc
lxc profile add ubc ubcp
lxc ls

lxc exec ubc -- less -RSi /var/log/cloud-init.log | grep 'Exit code:'
lxc exec ubc -- less -RSi /var/log/cloud-init-output.log | grep WARNING
