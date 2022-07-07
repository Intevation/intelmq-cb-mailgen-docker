#!/bin/bash

set -xeu -o pipefail

sudo apt install -y wget uuid-runtime jq

password=$(uuidgen)

# Tests adduser script
#fody-adduser --user second --password "$password"

# Check Fody Frontend
wget -O - http://localhost:1382/ > /dev/null

# Test API Login
token=$(wget -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" http://localhost:1340/api/login/ 2>/dev/null | jq .login_token | tr -d '"')

# Test ContactDB
ip_search=$(wget -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/searchcidr?address=80.245.144.218)
test "$ip_search" = '{"manual": [], "auto": [617]}'

org_search=$(wget -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/org/auto/617)
test "$org_search" = '{"name": "ITZBUND", "sector_id": null, "comment": "", "ripe_org_hdl": "ORG-BFF1-RIPE", "ti_handle": "", "first_handle": "", "import_source": "ripe", "import_time": "2022-07-07T13:19:20.245681", "organisation_id": 617, "asns": [{"organisation_automatic_id": 617, "asn": 35704, "import_source": "ripe", "import_time": "2022-07-07T13:19:20.245681"}], "contacts": [{"contact_automatic_id": 1509, "firstname": "", "lastname": "", "tel": "", "openpgp_fpr": "", "email": "lir@list.bfinv.de", "comment": "", "import_source": "ripe", "import_time": "2022-07-07T13:19:20.245681", "organisation_automatic_id": 617}], "national_certs": [], "networks": [{"network_id": 10838, "address": "80.245.144.0/20", "comment": ""}, {"network_id": 3756, "address": "2a09:1480::/29", "comment": ""}], "fqdns": []}'
email_search=$(wget -O - --header "Authorization: $token" http://localhost:1382/api/contactdb/email/lir@list.bfinv.de)
test "$email_search" = '{"email": "lir@list.bfinv.de", "enabled": true, "tags": {}}'

# Test EventDB
wget -O - --header "Authorization: $token" http://localhost:1382/api/events/subqueries

if [ "$USE_CERTBUND" == "true" ]; then
    # check the statistics by checking if there's at least a count in the response
    after=$(date --rfc-3339\=seconds --date="today 00:00" | grep -Eo '^[0-9-]{10} [0-9:]{5}')
    before=$(date --rfc-3339\=seconds --date="tomorrow 00:00" | grep -Eo '^[0-9-]{10} [0-9:]{5}')
    wget -O - --header "Authorization: $token" "http://localhost:1382/api/events/stats?time-observation_after=$after&time-observation_before=$before&source-ip_is=80.245.144.218&timeres=hour" | grep count
    # for the detailed search, just check if the address is somewhere -> result is complete
    wget -O - --header "Authorization: $token" "http://localhost:1382/api/events/search?time-observation_after=$after&time-observation_before=$before&source-ip_is=80.245.144.218" | grep lir@list.bfinv.de
fi

echo "Fody tests completed successfully!"
