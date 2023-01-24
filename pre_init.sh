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

echo "Deployment In Progress."
sleep 500
echo "Deployment Is Complete."

echo "Dynamic Port Forwarding Enabled."
ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')

# Check if the URL is accessible
status_code=$(curl -s -o /dev/null -w "%{http_code}" http://$(terraform output private_ec2_private_ip_slave1 | tr -d '"'):8080)

# Check if the status code is 200 (OK)
if [ $status_code -eq 200 ]; then
  sleep 1;
  echo "URL is accessible"
else
  echo "URL is not accessible, re-running SSH command for port forwarding"
  ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')
fi


echo "Enable socks proxy in the browser and forward to localhost:9090.\n"
echo "Access Web Application Locally: http://$(terraform output private_ec2_private_ip_slave1 | tr -d '"'):8080"
echo "Access kubernetes Dashboard Locally: http://$(terraform output private_ec2_private_ip_slave1 | tr -d '"'):30033"


echo "Run command terraform folder to enabled dynamic port forwarding to access application locally: ssh -D 9090 -f -C -q -N -i bastion_key.pem -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')"
echo "Globally Access Application via : `ssh -o ProxyCommand="ssh -i bastion_key.pem -W %h:%p -o StrictHostKeyChecking=no ubuntu@$(terraform output bastion_host_public_ip | tr -d '"')" -o StrictHostKeyChecking=no -i ec2_key.pem ubuntu@$(terraform output private_ec2_private_ip_slave1 | tr -d '"') "curl --silent http://localhost:4040/api/tunnels|jq '.tunnels[0].public_url'" | tr -d '"'`"

alias cd_back="cd ../../"
cd_back
echo "Run post_scrit.sh to destroy."
echo "Lab Deployed Successfully."

