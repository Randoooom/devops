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
    sh ./bootstrap/scripts/start_bastion_sessions.sh 2> temp

    sleep 2

    if grep -q "Permission denied" temp; then \
        AWS_REQUEST_CHECKSUM_CALCULATION="when_required" terraform -chdir=./bootstrap/bastion apply -input=false -auto-approve -var-file ../.tfvars; \
        sleep 5; \
        rm -f temp; \
        just bastion; \
    fi
    rm -f temp || true

# terraform

init MODULE:
  AWS_REQUEST_CHECKSUM_CALCULATION="when_required" terraform -chdir=./bootstrap/{{MODULE}} init -var-file ../.tfvars -backend-config ../.backend.config -backend-config .backend.config

validate MODULE:
  just init {{MODULE}}

  AWS_REQUEST_CHECKSUM_CALCULATION="when_required" terraform -chdir=./bootstrap/{{MODULE}} validate 

plan MODULE: bastion
  just validate {{MODULE}}

  AWS_REQUEST_CHECKSUM_CALCULATION="when_required" terraform -chdir=./bootstrap/{{MODULE}} plan -input=false -var-file ../.tfvars

apply MODULE: bastion
  just validate {{MODULE}}

  AWS_REQUEST_CHECKSUM_CALCULATION="when_required" terraform -chdir=./bootstrap/{{MODULE}} apply -input=false -auto-approve -var-file ../.tfvars
