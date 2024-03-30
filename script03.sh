#!/usr/bin/env bash



# check for errors from boot scripts:
lxc exec ubc -- less -RSi /var/log/cloud-init.log | grep 'Exit code:'
lxc exec ubc -- less -RSi /var/log/cloud-init-output.log



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
