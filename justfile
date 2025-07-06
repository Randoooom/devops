install:
 pre-commit install 

git-secret-hide:
  git secret hide

git-secret-reveal:
  git secret reveal

# bastion access

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
    #!/usr/bin/env sh
    find gitops/templates/**/secrets/ -type f -name '*.yaml' | while read -r file; do
        if grep -q "kind: Secret" "$file"; then
            echo "Sealing $file..."
            kubeseal -f "$file" -w "$file"
        fi
    done

plan:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a plan --queue-exclude-dir bastion --experiment cli-redesign

apply:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a apply --queue-exclude-dir bastion --experiment cli-redesign
