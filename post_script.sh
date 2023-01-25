#!/bin/bash

echo "###############################################################################"
echo "#                             KubeKrack                                       #"
echo "#                  Vulnerable Kubernetes Demo Lab                             #"
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

# change the directory back to the main
alias cd_temp="cd ../../"
cd_temp

echo "###############################################################################"
echo "# Terraform destroy complete                                                  #"
echo "###############################################################################"
# exit the script with a proper status code
exit 0
