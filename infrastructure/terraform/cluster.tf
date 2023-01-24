# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

resource "random_string" "example" {
  length = 5
}

# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "My VPC"
  }
}

# Create the public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-${random_string.example.result}"
  }
}

# Create the private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private-Subnet-${random_string.example.result}"
  }
}


# Create the Private NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.my_vpc.id

  # Inbound Rules
  ingress {
    rule_no = 100
    protocol    = "tcp"
    action      = "allow"
    cidr_block  = "10.0.0.0/24"
    from_port   = 22
    to_port     = 22
  }
  ingress {
    rule_no = 200
    protocol    = "tcp"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 1024
    to_port     = 65535
  }

  # Outbound Rules
  egress {
    rule_no = 100
    protocol    = "tcp"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 80
    to_port     = 80
  }
  egress {
    rule_no = 200
    protocol    = "tcp"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 443
    to_port     = 443
  }
  egress {
    rule_no = 300
    protocol    = "tcp"
    action      = "allow"
    cidr_block  = "10.0.0.0/24"
    from_port   = 32768
    to_port     = 61000
  }
}

# Associate the Private NACL with the private subnet
resource "aws_network_acl_association" "private_nacl_assoc" {
  subnet_id   = aws_subnet.private_subnet.id
  network_acl_id = aws_network_acl.private_nacl.id
}


# Create a key pair for the EC2 instance in the private subnet
resource "tls_private_key" "ec2_key_pair" {
  algorithm = "RSA"
}

resource "local_file" "ec2_ssh_key" {
  content  = tls_private_key.ec2_key_pair.private_key_pem
  filename = "ec2_key.pem"
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2_key_pair.public_key_openssh
}

#Create master & slave nodes for kubernetes cluster
# Create the EC2-master instance in the private subnet
resource "aws_instance" "private_ec2_m" {
  ami = "ami-0135afc6d226a70a4"
  instance_type = "t2.medium"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  # Install and start the Kubeadm
  user_data = <<EOF
#!/bin/bash
wget https://raw.githubusercontent.com/justmorpheus/insecure-python-microservice/main/infrastructure/ansible/script.sh -O /tmp/script.sh
chmod +x /tmp/script.sh
EOF


  root_block_device {
    volume_size   = "20"

  }
  

  tags = {
    Name = "Master-${random_string.example.result}"
  }
}

# Create the EC2-1 instance in the private subnet
resource "aws_instance" "private_ec2_1" {
  ami = "ami-0135afc6d226a70a4"
  instance_type = "t2.medium"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  # Install and start the Kubeadm
  user_data = <<EOF
#!/bin/bash
wget https://raw.githubusercontent.com/justmorpheus/insecure-python-microservice/main/infrastructure/ansible/script.sh -O /tmp/script.sh
chmod +x /tmp/script.sh
EOF

  root_block_device {
    volume_size   = "20"

  }

  tags = {
    Name = "Worker-1-${random_string.example.result}"
  }
}

# Create the EC2-2 instance in the private subnet
resource "aws_instance" "private_ec2_2" {
  ami = "ami-0135afc6d226a70a4"
  instance_type = "t2.medium"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  # Install and start the Kubeadm
  user_data = <<EOF
#!/bin/bash
wget https://raw.githubusercontent.com/justmorpheus/insecure-python-microservice/main/infrastructure/ansible/script.sh -O /tmp/script.sh
chmod +x /tmp/script.sh
EOF
  
  root_block_device {
    volume_size   = "20"

  }

  tags = {
   Name = "Worker-2-${random_string.example.result}"
  }
}

# Create the EC2-3 instance in the private subnet
resource "aws_instance" "private_ec2_3" {
  ami = "ami-0135afc6d226a70a4"
  instance_type = "t2.medium"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id
  # Install and start the Kubeadm
  user_data = <<EOF
#!/bin/bash
wget https://raw.githubusercontent.com/justmorpheus/insecure-python-microservice/main/infrastructure/ansible/script.sh -O /tmp/script.sh
chmod +x /tmp/script.sh
EOF
  
  root_block_device {
    volume_size   = "20"

  }

  tags = {
   Name = "Worker-3-${random_string.example.result}"
  }
}


# Create the security group for the Private host
resource "aws_security_group" "private_sg" {
  name = "private_sg"
  description = "Security group for the Private host"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "Allow Bastion ssh access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    description = "Allow application running on 8080"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    description = "Allow SSH between interna nodes"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
  ingress {
    description = "Allow kubernetes Dashboard"
    from_port = 30033
    to_port = 30033
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    description = "Allow outbound"
    from_port = 0
    to_port = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# Create a key pair for the Bastion host
resource "tls_private_key" "bastion_key_pair" {
  algorithm = "RSA"
}

resource "local_file" "bastion_ssh_key" {
  content  = tls_private_key.bastion_key_pair.private_key_pem
  filename = "bastion_key.pem"
}

resource "aws_key_pair" "bastion_key_pair" {
  key_name   = "bastion_key"
  public_key = tls_private_key.bastion_key_pair.public_key_openssh
}

#Create a policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy_k8slab"
  path        = "/"
  description = "Policy to provide permission to EC2 Bastion host"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        }
    ]
})
}

#Create a role
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Attach role to policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name       = "ec2_attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.ec2_policy.arn
}

#Attach role to an instance profile
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}


# Create the Bastion host in the public VPC
resource "aws_instance" "bastion_host" {
  ami = "ami-0135afc6d226a70a4"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.bastion_key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y software-properties-common awscli ansible
bash -c "echo $(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Master*' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region us-west-2) 'IP_MASTER' >> /etc/hosts"
bash -c "echo $(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-1*' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region us-west-2) 'IP_WORKER_1' >> /etc/hosts"
bash -c "echo $(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-2*' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region us-west-2) 'IP_WORKER_2' >> /etc/hosts"
bash -c "echo $(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text --region us-west-2) 'IP_WORKER_3' >> /etc/hosts"
git clone https://github.com/justmorpheus/insecure-python-microservice /home/ubuntu/insecure-python-microservice
mkdir /home/ubuntu/kube-cluster
cp /home/ubuntu/insecure-python-microservice/infrastructure/ansible/hosts  /home/ubuntu/kube-cluster/hosts
cp /home/ubuntu/insecure-python-microservice/infrastructure/ansible/ansible.cfg  /home/ubuntu/kube-cluster/ansible.cfg
chown ubuntu:ubuntu -R /home/ubuntu/
echo "ANSIBLE_CONFIG=/home/ubuntu/kube-cluster/ansible.cfg" >> /etc/environment
echo "ANSIBLE_INVENTORY=/home/ubuntu/kube-cluster/hosts" >> /etc/environment
source /etc/environment
sleep 10
# Check if the file exists
while [ ! -f /home/ubuntu/ec2_key.pem ]; do
  echo "File not found, waiting for 5 seconds"
  sleep 5
done
echo "File found, continuing with script"
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-1*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-1/{}/g' /home/ubuntu/insecure-python-microservice/frontend/k8s/deployment.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-2*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-2/{}/g' /home/ubuntu/insecure-python-microservice/backend/k8s/deployment.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/CVE-2021-25741/pod.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/bad-pod/badpod.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/bad-pod/dnd.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/bad-pod/deepdive-aws.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/secret-pod/legacy-pod.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-1*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-1/{}/g' /home/ubuntu/insecure-python-microservice/kyverno/restrictnodeselectionworker1.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-2*' --query "Reservations[].Instances[].PrivateDnsName" --output text --region us-west-2 | cut -d '.' -f1 | awk '{print $1}' | xargs -I {} sed -i -e 's/Worker-2/{}/g' /home/ubuntu/insecure-python-microservice/kyverno/restrictnodeselectionworker2.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-1*' --query "Reservations[].Instances[].PrivateIpAddress" --output text --region us-west-2  | xargs -I {} sed -i -e 's/Worker-1/{}/g' /home/ubuntu/insecure-python-microservice/frontend/k8s/service.yaml
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Worker-3*' --query "Reservations[].Instances[].PrivateIpAddress" --output text --region us-west-2  | xargs -I {} sed -i -e 's/Worker-3/{}/g' /home/ubuntu/insecure-python-microservice/worker-3/k8-dashboard/k8s-dashboard.yaml
echo "starting master playbook"
sudo ansible-playbook /home/ubuntu/insecure-python-microservice/infrastructure/ansible/master.yaml
sleep 5
echo "starting worker playbook"
sudo ansible-playbook /home/ubuntu/insecure-python-microservice/infrastructure/ansible/worker.yml 
EOF

  

  tags = {
    Name = "Bastion-Host-${random_string.example.result}"
  }
}

# Create the security group for the Bastion host
resource "aws_security_group" "bastion_sg" {
  name = "bastion_sg"
  description = "Security group for the Bastion host"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "Allow SSH access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound"
    from_port = 0
    to_port = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the Internet Gateway for the public VPC
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Public Internet Gateway"
  }
}

# Create the public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Create the route table for the private VPC
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id


  route {
  cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

  tags = {
    Name = "Private Route Table"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}



# Create an Elastic IP for the NAT gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Create the NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}


# Output the Bastion host public IP address
output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
  description = "Public IP address of the Bastion host"
}


# Output the private-ec2-master host private IP address
output "private_ec2_private_ip_master" {
  value = aws_instance.private_ec2_m.private_ip
  description = "Private IP address of the Ec2 host"
}


# Output the private-ec2-slave-1 host private IP address
output "private_ec2_private_ip_slave1" {
  value = aws_instance.private_ec2_1.private_ip
  description = "Private IP address of the Ec2 host"
}


# Output the private-ec2-slave-2 host private IP address
output "private_ec2_private_ip_slave2" {
  value = aws_instance.private_ec2_2.private_ip
  description = "Private IP address of the Ec2 host"
}
  

# Output the private-ec2-slave-3 host private IP address
output "private_ec2_private_ip_slave3" {
  value = aws_instance.private_ec2_3.private_ip
  description = "Private IP address of the Ec2 host"
}
