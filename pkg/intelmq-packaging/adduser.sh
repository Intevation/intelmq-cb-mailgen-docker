#!/bin/bash

if [ -z "$HOST_UID" ] || [ -z "$HOST_USERNAME" ]; then
cat << EOF
			      USER ACCOUNT WARNING

Not automatically adding user account.  If you intend to build packages on
a volume, you should add a user that matches your user account's ID on the host
system, e.g., \`useradd -u \$HOST_UID \$HOST_USERNAME\`.

You can start a container with the following options if you want the account to
be added for you:

  --env=HOST_UID=\$(id -u) --env=HOST_USERNAME=\$(whoami)

EOF
else
  echo "Adding user $HOST_USERNAME ($HOST_UID)..."
  useradd --uid "$HOST_UID" --create-home "$HOST_USERNAME"
  echo "Switch to the user with \`su $HOST_USERNAME\`."
fi

echo "Entering interactive session..."
/bin/bash

# vim :set noet sts=0 sw=2 ts=8:
