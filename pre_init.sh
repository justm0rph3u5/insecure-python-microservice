#!/bin/bash
set +e
echo "Make sure terraform in installed"
echo "Current AWS region is set to us-west-2"

alias cdtemp="cd infrastructure/terraform"
cdtemp

terraform init
terraform apply --auto-approve

chmod 400 ec2_key.pem
chmod 400 bastion_key.pem



scp -o StrictHostKeyChecking=no -i bastion_key.pem ec2_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"'):~/

echo "Wait for 6-7 minutes while infra deployment is happening. "
sleep 385
echo "Now ssh into bastion to access the application "
echo "To ssh: ssh -o StrictHostKeyChecking=no -i bastion_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"') "

echo "To cleanup run: terraform destroy --auto-approve"

