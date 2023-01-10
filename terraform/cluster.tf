# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
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
    Name = "Public Subnet"
  }
}

# Create the private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private Subnet"
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
# Create the EC2-1 instance in the private subnet
resource "aws_instance" "private_ec2_m" {
  ami = "ami-0ecc74eca1d66d8a6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id

  tags = {
    Name = "Master"
  }
}

# Create the EC2-1 instance in the private subnet
resource "aws_instance" "private_ec2_1" {
  ami = "ami-0ecc74eca1d66d8a6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id

  tags = {
    Name = "Worker-1"
  }
}

# Create the EC2-1 instance in the private subnet
resource "aws_instance" "private_ec2_2" {
  ami = "ami-0ecc74eca1d66d8a6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id = aws_subnet.private_subnet.id

  tags = {
   Name = "Worker-2"
  }
}


# Create the security group for the Private host
resource "aws_security_group" "private_sg" {
  name = "private_sg"
  description = "Security group for the Private host"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "Allow SSH access"
    from_port = 22
    to_port = 22
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

# Create the Bastion host in the public VPC
resource "aws_instance" "bastion_host" {
  ami = "ami-0ecc74eca1d66d8a6"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.bastion_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "Bastion Host"
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
  subnet_id     = aws_subnet.private_subnet.id
}


# Output the Bastion host public IP address
output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
  description = "Public IP address of the Bastion host"
}


# Output the private-ec2-master host private IP address
output "private_ec2_private_ip" {
  value = aws_instance.private_ec2_m.private_ip
  description = "Private IP address of the Ec2 host"
}


# Output the private-ec2-slave-1 host private IP address
output "private_ec2_private_ip" {
  value = aws_instance.private_ec2_1.private_ip
  description = "Private IP address of the Ec2 host"
}


# Output the private-ec2-slave-2 host private IP address
output "private_ec2_private_ip" {
  value = aws_instance.private_ec2_2.private_ip
  description = "Private IP address of the Ec2 host"
}
