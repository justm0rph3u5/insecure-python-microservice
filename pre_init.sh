#!/bin/bash
echo "Make sure terraform in installed"
echo "Current AWS region is set to us-west-2"

alias cd_temp="cd infrastructure/terraform"
cd_temp
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

echo "Deployment In Progress.\n"
sleep 500
echo "Deployment Is Complete.\n"

echo "Dynamic Port Forwarding Enabled."
ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')

echo "Enable socks proxy in the browser and forward to localhost:9090.\n"
echo "Access Web Application: $(terraform output private_ec2_private_ip_slave1 | tr -d '"'):8080"
echo "Access kubernetes Dashboard: $(terraform output private_ec2_private_ip_slave1 | tr -d '"'):30033"

alias cd_back="cd ../../"
cd_back
echo "Run command terraform folder to enabled dynamic port forwarding to access application locallly: ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')"
echo "Run post_scrit.sh to destroy.\n"
echo "Lab Deployed Successfully."

