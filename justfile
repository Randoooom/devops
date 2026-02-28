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

plan:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a plan --queue-exclude-dir bastion --experiment cli-redesign

apply:
  cd bootstrap && TF_VAR_vpn_connected=true terragrunt run -a apply --queue-exclude-dir bastion --experiment cli-redesign

provision PHYSICAL:
  #!/usr/bin/sh

  # change to the referenced physical stack
  cd physical/{{ PHYSICAL }}
  # prepare outputs
  mkdir -p inventory/.output
  # decrypt the ssh for ansible
  sops decrypt --output-type json ssh.sops.yaml | jq -r '.private_key' > inventory/.output/key

  # install ansible modules
  ansible-galaxy install -r requirement.yaml

  # init all terragrunt modules (yes terragrunt does not support -chdir)
  fd -t dir -d 1 . tofu -x sh -c 'cd {} && terragrunt init'

  just run

encrypt:
  fd .sops.yaml -X grep -L '^sops:' {} | xargs -I {} sops encrypt -i {}
