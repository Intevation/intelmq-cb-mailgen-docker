#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

function end_test {
    read line file <<<$(caller)
    echo "Mailgen test failed at $file:$line. Run with DEBUG=1 to get more details of the failure."
    # restore original 10shadowservercsv.py script
    $docker intelmq-mailgen mv $script.bak $script
    $docker intelmq-mailgen cp $config.bak $config
    $docker intelmq-mailgen rm /tmp/intelmqcbmail_disabled
}
trap end_test ERR

docker="docker exec --env-file=.env -e DEBUG=${DEBUG-}"
script=/opt/formats/10shadowservercsv.py
config=/etc/intelmq/intelmq-mailgen.conf

# ../testall.sh creates the file too. When this test script is run alone, create the file.
$docker intelmq-mailgen touch /tmp/intelmqcbmail_disabled

# Check executable itself by calling help page
$docker intelmq-mailgen intelmqcbmail -h

# Manipulate shadowserver rule to allow sending the data right now without waiting
$docker intelmq-mailgen cp $script $script.bak
$docker intelmq-mailgen sed -i 's/minutes=15/seconds=2/' $script
$docker intelmq-mailgen sed -i 's/hours=2/seconds=2/' $script
$docker intelmq-mailgen cp $config $config.bak
$docker intelmq-mailgen sed -i 's/INFO/DEBUG/' $config

cbmail_out=$($docker intelmq-mailgen intelmqcbmail --all --verbose 2>&1)

echo "$cbmail_out" | grep "Calling script '$script'"
echo "$cbmail_out" | grep '1 mails sent'
[[ "$cbmail_out" =~ New\ ticket\ number ]]

$docker intelmq-dsmtpd tail -n 1 /var/log/dsmtpd.log | fgrep ' -> nic-itzbund@itzbund.de [IntelMQ-Mailgen#'

echo "Mailgen tests completed successfully!"

# Restore previous environment
$docker intelmq-mailgen mv $script.bak $script
$docker intelmq-mailgen rm /tmp/intelmqcbmail_disabled
$docker intelmq-mailgen cp $config.bak $config
