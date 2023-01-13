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

# Check if the key file exists on the server
if ssh -o StrictHostKeyChecking=no -i bastion_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"') "ls /home/ubuntu/ec2_key.pem" ; then
  echo "Ssh Key file already exists on the server"
else
  echo "Key file not found on the server, copying now"
  scp -o StrictHostKeyChecking=no -i bastion_key.pem ec2_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"'):~/
fi

echo "Wait for 6-7 minutes while infra deployment is happening. "
sleep 385
echo "Now ssh into bastion to access the application "
echo "To ssh: ssh -D 9090 -o StrictHostKeyChecking=no -i bastion_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"') "

echo "To cleanup run: terraform destroy --auto-approve"

