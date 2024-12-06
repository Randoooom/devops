.PHONY: oci cluster


init-oci:
	terraform -chdir=./oci init -var-file ../tfvars -var-file ../.tfvars -backend-config ../.backend.config -backend-config .backend.config

init-cluster:
	terraform -chdir=./cluster init -var-file ../tfvars -var-file ../.tfvars -backend-config ../.backend.config -backend-config .backend.config

validate-oci: init-oci
	terraform -chdir=./oci validate

validate-cluster: init-cluster
	terraform -chdir=./cluster validate

plan-oci: validate-oci
	terraform -chdir=./oci plan -input=false -var-file ../tfvars -var-file ../.tfvars

plan-cluster: validate-cluster
	terraform -chdir=./cluster plan -input=false -var-file ../tfvars -var-file ../.tfvars

apply-oci: validate-oci
	terraform -chdir=./oci apply -input=false -var-file ../tfvars -var-file ../.tfvars

apply-cluster: validate-cluster
	terraform -chdir=./cluster apply -input=false -var-file ../tfvars -var-file ../.tfvars

bastion-sessions: validate-oci
	terraform -chdir=./oci apply -input=false -var-file ../tfvars -var-file ../.tfvars -target=module.nodes.oci_bastion_session.worker -target=module.nodes.oci_bastion_session.controlplane -target=module.nodes.oci_bastion_session.kubernetes_controlplane

start-bastion-sessions:
	sh scripts/start_bastion_sessions.sh

stop-bastion-sessions:
	sh scripts/stop_bastion_sessions.sh
