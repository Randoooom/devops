stop-bastion:
  sh ./bootstrap/scripts/stop_bastion_sessions.sh

bastion:
    sh ./bootstrap/scripts/start_bastion_sessions.sh 2> .bastion

    sleep 2

    if grep -q "Permission denied" .bastion; then \
        cd ./bootstrap/bastion && terragrunt  apply -input=false -auto-approve && cd ../..; \
        sleep 5; \
        rm -f .bastion; \
        just bastion; \
    fi
    rm -f .bastion || true

seal:
  fd . gitops -e .enc.yaml -x sh -c 'sops decrypt {} | kubeseal -o yaml > "$(dirname {})/$(basename {} .enc.yaml).sealed.yaml"'

plan:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a plan --queue-exclude-dir bastion --experiment cli-redesign

apply:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a apply --queue-exclude-dir bastion --experiment cli-redesign
