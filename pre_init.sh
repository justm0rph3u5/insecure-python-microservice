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
# Check if the key file exists on the server
if ssh -o StrictHostKeyChecking=no -i bastion_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"') "ls /home/ubuntu/ec2_key.pem" ; then
  echo "Ssh Key file already exists on the server"
else
  echo "Key file not found on the server, copying now"
  scp -o StrictHostKeyChecking=no -i bastion_key.pem ec2_key.pem ubuntu@$(terraform output bastion_host_public_ip | tr -d '"'):~/
fi

echo "Wait for 10 minutes while infra deployment is happening. "
sleep 500

echo "Enabling dynamic application level port forwarding."
ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')

echo "Now enable socks proxy in the browser and forward to localhost:9090, use foxyproxy to access the internal application at $(terraform output private_ec2_private_ip_slave1 | tr -d '"'):8080"
echo "Access kubernetes Dashboard at $(terraform output private_ec2_private_ip_slave1 | tr -d '"'):30033"

echo "To cleanup run: terraform destroy --auto-approve"

