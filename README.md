<!--TOC-->

- [purpose](#purpose)
- [getting started: install incus](#getting-started-install-incus)
- [example: create container based off ubuntu 22.04](#example-create-container-based-off-ubuntu-2204)
- [example: assign a network profile to a container](#example-assign-a-network-profile-to-a-container)
- [example: run some scripts at boot](#example-run-some-scripts-at-boot)

<!--TOC-->

# purpose

Create quickstart guide for incus and cloud-init.  I keep forgetting this stuff, so I'm writing it down.

# getting started: install incus

```bash
# file: incus.sh
# FIXME: inline these scripts
curl https://raw.githubusercontent.com/taylormonacelli/ringgem/master/install-kibbly-stable-sources-on-ubuntu.sh | sudo bash
curl https://raw.githubusercontent.com/taylormonacelli/ringgem/master/install-incus-on-ubuntu.sh | sudo bash

incus admin init --auto
```

# example: create container based off ubuntu 22.04


- remove container ubc if it exists
- launch ubuntu container and arbitrarily name it ubc


```bash
# file: script01.sh
# remove container ubc if it exists
incus ls --format=json | jq 'map(select(.name == "ubc")) | .[] | .name' | xargs --no-run-if-empty -I {} incus delete --force {}

# launch ubuntu 22.04 container and name it ubc
incus launch images:ubuntu/22.04 ubc
incus ls
```


# example: assign a network profile to a container


Use [cloud-init](https://cloudinit.readthedocs.io/en/latest/howto/run_cloud_init_locally.html#lxd) to allow me ssh access, install some some packages and reboot contanier.


```bash
# file: script02.sh
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

# create container ubc
incus launch images:ubuntu/22.04/cloud ubc --config=user.user-data="$(cat cloud-init-ubc.yml)"

# assign profile ubcp to container ubc
incus profile add ubc ubcp
incus ls
```


# example: run some scripts at boot


Same as previous example but add run-once script using [`runcmd:`](https://cloudinit.readthedocs.io/en/latest/reference/examples.html#run-commands-on-first-boot) in cloud-init.yml.

When cloud-init sees runcmd element, then it generates `/var/lib/cloud/instance/scripts/runcmd` and runs it.

In this example I intentionally make script1 fail in order to see if the next script will run or whether all subsequent scripts fail.


```bash
# file: script03.sh
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

    exit 1 # intentionally fail script1

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

# create container ubc
incus launch images:ubuntu/22.04/cloud ubc --config=user.user-data="$(cat cloud-init-ubc.yml)"

# assign profile ubcp to container ubc
incus profile add ubc ubcp
incus ls

# get error we generated by intentionally failing script1
incus exec ubc -- less -RSi /var/log/cloud-init.log | grep 'Exit code:'
incus exec ubc -- less -RSi /var/log/cloud-init-output.log | grep WARNING
```

We can see failure on script1 in cloud init logs.

Search for "Exit code" in `/var/log/cloud-init.log`.  There it shows the runcmd failed since script1 exited with nonzero exit code.

Check last 10 lines or so from here and you'll notice the `touch /tmp/$(date +%s).txt` from script2 never ran since script1 failed.
