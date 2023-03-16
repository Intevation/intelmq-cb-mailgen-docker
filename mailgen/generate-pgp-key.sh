#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

# create gnupg homedir, if it does not exist (dev scenarios)
mkdir -p /etc/intelmq/mailgen/gnupghome/
gpg="gpg --homedir /etc/intelmq/mailgen/gnupghome"

# based on https://serverfault.com/a/960673/217116
cat >keydetails <<EOF
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Name-Real: IntelMQ Test
    Name-Comment: IntelMQ Test
    Name-Email: noreply@example.com
    Expire-Date: 0
    %no-ask-passphrase
    %no-protection
    %commit
EOF

$gpg --batch --gen-key keydetails

# check if the key works
echo foobar | $gpg -e -a -r noreply@example.com

# update the mailgen configuration
key_id=$($gpg -K | grep -Eo '[A-F0-9]{40}' | head -n1)
sed -i "s/5F503EFAC8C89323D54C252591B8CD7E15925678/$key_id/" /etc/intelmq/intelmq-mailgen.conf

echo "Mailgen PGP key successfully generated and configured."
