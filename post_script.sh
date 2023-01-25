#!/bin/bash

echo "###############################################################################"
echo "#                             KubeKrack                                       #"
echo "#                   A Vulnerable Kubernetes Lab                               #"
echo "#                                                                             #"
echo "#                           Deletion Script                                   #"
echo "#                                                                             #"
echo "#                  Thank you for using KubeKrack Lab                          #"
echo "#                                                                             #"
echo "###############################################################################"

# Disable the socks proxy
unset http_proxy
unset https_proxy

# Change directory to infrastructure/terraform
alias cd_temp="cd infrastructure/terraform"
cd_temp

# Run terraform destroy command
terraform destroy --auto-approve

# Remove terraform related files and folders
rm -rf .terraform*
rm -rf terraform.tfstate*

# change the directory back to the main
alias cd_temp="cd ../../"
cd_temp

echo "###############################################################################"
echo "# Terraform destroy complete                                                  #"
echo "###############################################################################"
# exit the script with a proper status code
exit 0
