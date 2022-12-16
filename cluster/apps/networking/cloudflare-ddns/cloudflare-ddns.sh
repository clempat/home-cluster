#!/usr/bin/env bash

set -o nounset
set -o errexit

current_ipv4="$(curl -s https://ipv4.icanhazip.com/)"
zone_id=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones?name=${CLOUDFLARE_DOMAIN}&status=active" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
        | jq --raw-output ".result[0] | .id"
)

# IPV4
record_ipv4=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=ipv4.${CLOUDFLARE_DOMAIN}&type=A" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
)
record_ipv4_identifier="$(echo "$record_ipv4" | jq --raw-output '.result[0] | .id')"
old_ip4=$(echo "$record_ipv4" | jq --raw-output '.result[0] | .content')
if [[ "${current_ipv4}" != "${old_ip4}" ]]; then
  update_ipv4=$(curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_ipv4_identifier}" \
      -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
      -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
      -H "Content-Type: application/json" \
      --data "{\"id\":\"${zone_id}\",\"type\":\"A\",\"proxied\":true,\"name\":\"ipv4.${CLOUDFLARE_DOMAIN}\",\"content\":\"${current_ipv4}\"}" \
  )

  if [[ "$(echo "$update_ipv4" | jq --raw-output '.success')" != "true" ]];then
    printf "%s - Yikes - Updating IP Address '%s' for ipv4 has failed" "$(date -u)" "${current_ipv4}"
    exit 1
  fi
fi

# Valheim
record_valheim=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=valheim.${CLOUDFLARE_DOMAIN}&type=A" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
)
record_valheim_identifier="$(echo "$record_valheim" | jq --raw-output '.result[0] | .id')"
old_ip4_valheim=$(echo "$record_valheim" | jq --raw-output '.result[0] | .content')

if [[ "${current_ipv4}" != "${old_ip4_valheim}" ]]; then
  update_valheim=$(curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_valheim_identifier}" \
      -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
      -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
      -H "Content-Type: application/json" \
      --data "{\"id\":\"${zone_id}\",\"type\":\"A\",\"proxied\":false,\"name\":\"valheim.${CLOUDFLARE_DOMAIN}\",\"content\":\"${current_ipv4}\"}" \
  )
  if [[ "$(echo "$update_valheim" | jq --raw-output '.success')" != "true" ]];then
    printf "%s - Yikes - Updating IP Address '%s' for valheim has failed" "$(date -u)" "${current_ipv4}"
    exit 1
  fi
fi

if [ -z ${update_ipv4+x} ] && [ -z ${update_valheim+x} ];then
    printf "%s - IP Address '%s' has not changed" "$(date -u)" "${current_ipv4}"
    exit 0
fi

printf "%s - Success - IP Address '%s' has been updated" "$(date -u)" "${current_ipv4}"
exit 0
