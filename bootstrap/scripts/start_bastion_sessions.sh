#!/bin/sh

cd ./bastion/
# get the bastion session data from the state
SESSIONS=$(terraform output -raw bastion_sessions)

cd ../oci/
region=$(terraform output -raw region)

cd ../

i=0

> .session

echo "$SESSIONS" | jq -c '.[]' | while IFS= read -r session; do
  bastion_user_name=$(echo $session | jq -r '.bastion_user_name')
  remote_port=$(echo $session | jq -r '.target_resource_details[0].target_resource_port')
  remote_host=$(echo $session | jq -r '.target_resource_details[0].target_resource_private_ip_address')
  session_id=$(echo $session | jq -r '.id')
  local_port=$((remote_port + i))

  ssh -o StrictHostKeyChecking=no -N -L "${local_port}:${remote_host}:${remote_port}" -p 22 "${session_id}@host.bastion.${region}.oci.oraclecloud.com" &
  echo $! >> .session

  i=$((i + 1))
done

wait
