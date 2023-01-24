#!/bin/bash

alias cd_temp="cd infrastructure/terraform"
cd_temp

terraform destroy --auto-approve
echo "Terraform destroy complete"

alias cd_temp="cd ../../"
cd_temp

