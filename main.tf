
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

module "ec2" {
  source = "github.com/cliffcole/ec2"

  ami_id            = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  name              = var.name
  environment       = var.environment
  region            = var.region
  instance_count    = var.instance_count
  subnet_id =   aws_subnet.public_subnet["public-subnet-1"].id
  security_groups = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  ssh_key_name = aws_key_pair.generated.key_name
  private_key_pem =   tls_private_key.generated.private_key_pem
  
}

#create VPC
module "vpc" {

  source          = "github.com/cliffcole/vpc"
  vpc_cidr        = var.vpc_cidr
  vpc_environment = var.environment
  vpc_name        = var.vpc_name

}


#Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = module.vpc.id
  tags = {
    Name = var.gateway_name
  }
}

#Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnet]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet["public-subnet-1"].id
  tags = {
    Name = var.nat_gateway_name
  }
}

resource "aws_eip" "nat_gateway_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = var.nat_gateway_eip_name
  }
}

#build public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = module.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = var.public_route_table_name
  }
}

#private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = module.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = var.private_route_table_name
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnet]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnet]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
}



resource "aws_subnet" "public_subnet" {
  for_each          = var.public_subnet
  vpc_id            = module.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone = var.sub_az
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.environment}-${each.key}"
    Terraform = true
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = var.private_subnet
  vpc_id            = module.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = var.sub_az


  tags = {
    Name      = "${var.environment}-${each.key}"
    Terraform = true
  }
}

# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "${var.environment}-vpc-web"
  vpc_id      = module.vpc.id
  description = "Web Traffic"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = module.vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = module.vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "ssh-key.pem"
}
resource "aws_key_pair" "generated" {
  key_name   = "ssh-key"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}