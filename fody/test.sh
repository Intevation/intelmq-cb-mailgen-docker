#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

function end_test {
    read line file <<<$(caller)
    echo "Fody Test failed at $file:$line. Run with DEBUG=1 to get more details of the failure."
}
trap end_test ERR

password=$(uuidgen)

# Tests adduser script
#fody-adduser --user second --password "$password"

# Check Fody Frontend
wget --no-verbose -O - http://localhost:1382/ > /dev/null

# Test API Login
token=$(wget --no-verbose -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" http://localhost:1382/api/login/ 2>/dev/null | jq .login_token | tr -d '"')

# Test ContactDB
# 80.245.144.218 is the address of bsi.bund.de
# owned by ORG-BFF1-RIPE (ITZBUND)
ip_search=$(wget --no-verbose -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/searchcidr?address=80.245.144.218)
echo $ip_search | grep -E '^\{"manual": \[\], "auto": \[[0-9]+\]\}$'
organisation=$(echo $ip_search | jq .auto[0])

org_search=$(wget --no-verbose -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/org/auto/$organisation)
echo "$org_search" | grep -E '\{"name": "ITZBUND", "sector_id": null, "comment": "", "ripe_org_hdl": "ORG-BFF1-RIPE", "ti_handle": "", "first_handle": "", "import_source": "ripe", "import_time": "[0-9-]{10}T[0-9:.]+", "organisation_id": [0-9]+, "asns": \[\{"organisation_automatic_id": [0-9]+, "asn": 35704, "import_source": "ripe", "import_time": "[0-9-]{10}T[0-9:.]+"\}\], "contacts": \[\{"contact_automatic_id": [0-9]+, "firstname": "", "lastname": "", "tel": "", "openpgp_fpr": "", "email": "sub-lir-bund@itzbund.de", "comment": "", "import_source": "ripe", "import_time": "[0-9-]{10}T[0-9:.]+", "organisation_automatic_id": [0-9]+\}\], "national_certs": \[\], "networks": \[\{"network_id": [0-9]+, "address": "80.245.144.0/20", "comment": ""\}, \{"network_id": [0-9]+, "address": "2a09:1480::/29", "comment": ""\}\], "fqdns": \[\]\}'
email_search=$(wget --no-verbose -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/email/sub-lir-bund@itzbund.de)
test "$email_search" = '{"email": "sub-lir-bund@itzbund.de", "enabled": true, "tags": {}}'

# Test EventDB
wget --no-verbose -O - --header "Authorization: $token" http://localhost:1382/api/events/subqueries

if [ "$USE_CERTBUND" == "true" ]; then
    # check the statistics by checking if there's at least a count in the response
    after=$(date --rfc-3339\=seconds --date="today 00:00" | grep -Eo '^[0-9-]{10} [0-9:]{5}')
    before=$(date --rfc-3339\=seconds --date="tomorrow 00:00" | grep -Eo '^[0-9-]{10} [0-9:]{5}')
    wget --no-verbose -O - --header "Authorization: $token" "http://localhost:1382/api/events/stats?time-observation_after=$after&time-observation_before=$before&source-ip_is=80.245.144.218&timeres=hour" | grep count
    # for the detailed search, just check if the address is somewhere -> result is complete
    wget --no-verbose -O - --header "Authorization: $token" "http://localhost:1382/api/events/search?time-observation_after=$after&time-observation_before=$before&source-ip_is=80.245.144.218" | grep sub-lir-bund@itzbund.de
fi

echo "Fody tests completed successfully!"
