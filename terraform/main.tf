terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = merge({ "Name" = "${var.prefix}-vpc" }, var.tags)
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true # Enable auto-assign public IP addresses
  tags                    = merge({ "Name" = "${var.prefix}-public-subnet" }, var.tags)
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  tags       = merge({ "Name" = "${var.prefix}-private-subnet" }, var.tags)
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, 2) # Offset to avoid conflict with public
}

resource "aws_internet_gateway" "gw" {
  tags   = merge({ "Name" = "${var.prefix}-internet-gw" }, var.tags)
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "main_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge({ "Name" = "${var.prefix}-main-route" }, var.tags)
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.main_route.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.main_route.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Create a separate EC2 Security Group to grant ingress and 
egress network traffic to the EC2 instance via the default
Subnet, Internet Gateway and Routing.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group" "interrupt_app" {
  name        = "interrupt_app"
  description = "Interrupt inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  tags        = merge({ "Name" = "Interrupt App NSG" }, var.tags)
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly allow all egress traffic for the scurity group. 
The CIDR should be changed to reflect the localized working
environment in the demo platform.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "egress_allow_all" {
  description       = "Allow all outbound traffic."
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept SSH traffic.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_ssh" {
  description       = "SSH Connection"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept PostgreSQL traffic from our VPC.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_postgres" {
  description       = "Postgres traffic"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main_vpc.cidr_block]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Create secret password for database instance
**** **** **** **** **** **** **** **** **** **** **** ****/
resource "random_password" "database" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

# Generate a random 10-digit numeric string
resource "random_id" "secret_postfix" {
  byte_length = 5 # This generates a 10-character string when converted to hexadecimal.
}

resource "aws_secretsmanager_secret" "database" {
  name = "${var.prefix}-db-password-${random_id.secret_postfix.hex}"
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id     = aws_secretsmanager_secret.database.id
  secret_string = random_password.database.result
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Define a private key pair to access the EC2 instance. Do not
expose the key outside fo the demo platform environment.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tls_private_key" "main" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key"
}

resource "aws_key_pair" "main" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.main.public_key_openssh
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Saving the key locally as an optional use case. It is not 
necessary for the demo sequence and can be omitted.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > ${var.prefix}-ssh-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.prefix}-ssh-key.pem"
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
The secret names to pass down
**** **** **** **** **** **** **** **** **** **** **** ****/
locals {
  POSTFIX = random_id.secret_postfix.hex
}

/**** **** **** **** **** **** **** **** **** **** **** ****
  Create a new instance of the latest Ubuntu on an EC2 instance,
  t2.micro node. We can find more options using the AWS command line:
 
  aws ec2 describe-images --owners 099720109477 \
    --filters "Name=name,Values=*hvm-ssd*focal*20.04-amd64*" \
    --query 'sort_by(Images, &CreationDate)[].Name'
 *** **** **** **** **** **** **** **** **** **** **** ****/
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

/**** **** **** **** **** **** **** **** **** **** **** ****
The primary purpose of this resource is to create and manage 
an EC2 instance within a specified VPC, ensuring it is properly 
configured with necessary dependencies, security settings, and 
initialization scripts.

Key Security Elements:
- depends_on: Ensures the instance is created only after the 
  specified internet gateway resource.

- key_name: Associates the instance with a specified key pair 
  for secure SSH access.

- vpc_security_group_ids: Attaches the instance to a specified 
  security group, controlling inbound and outbound traffic.

- user_data_base64: Encodes and provides user data for instance 
  initialization, including sensitive information like database 
  passwords, ensuring they are securely passed to the instance.

- iam_instance_profile: Attaches a specified IAM instance profile 
  to the instance, granting it necessary permissions to interact 
  AWS secrets manager and S3.
*** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_instance" "database" {
  depends_on                  = [aws_internet_gateway.gw]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.interrupt_app.id]
  user_data_base64            = base64encode("${templatefile("${path.module}/templates/user-data.bash", { PREFIX = "${var.prefix}", POSTFIX = "${local.POSTFIX}" })}")
  tags                        = merge({ "Name" = "${var.prefix}-ubuntu" }, var.tags)
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.main.private_key_pem
    host        = aws_instance.database.public_ip
  }

  # Provisioner to copy files for backup-service
  provisioner "file" {
    source      = "postgres-backup"
    destination = "/home/ubuntu/postgres-backup"
  }

  # JSON data to create app database
  provisioner "file" {
    source      = "db-data"
    destination = "/home/ubuntu/db-data"
  }

}


