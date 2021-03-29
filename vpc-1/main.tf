# Define AWS as our provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/18"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "Main NAT Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Setup Security Groups
resource "aws_security_group" "New_Web_SG" {
  name        = "Web_Tier_Traffic"
  description = "Allow TLS, ssh and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "New_Web_SG"
  }
}

resource "aws_security_group" "New_DB_SG" {
  name        = "DB_Traffic"
  description = "Allow ssh inbound traffic from web_SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from Web Tier"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
    security_groups = [aws_security_group.New_Web_SG.id]
  }

  ingress {
    description = "icmp from VPC"
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "New_DB_SG"
  }
}

# Launch 1st instance (t2.micro instance with free linux AMI)
resource "aws_instance" "Web_Instance" {
  ami               = "ami-0c94855ba95c71c99"
  instance_type     = "t2.micro"
  key_name          = "KeyPair"

  subnet_id         = aws_subnet.public.id
  security_groups = [aws_security_group.New_Web_SG.id]
  depends_on        = [aws_internet_gateway.igw]

  tags = {
      Name = "New_Pub_Web_Instance"
  }
}

# Launch Bastion host in public subnet (t2.micro instance with linux AMI)
resource "aws_instance" "Bastion_Instance" {
  ami               = "ami-0c94855ba95c71c99"
  instance_type     = "t2.micro"
  key_name          = "KeyPair"

  subnet_id         = aws_subnet.public.id
  security_groups = [aws_security_group.New_Web_SG.id]
  depends_on        = [aws_internet_gateway.igw]

  tags = {
      Name = "New_Bastion_Instance"
  }
}

# Launch DB instance in private subnet (t2.micro instance with free linux AMI)
resource "aws_instance" "DB_Instance" {
  ami                = "ami-0c94855ba95c71c99"
  instance_type      = "t2.micro"
  key_name           = "KeyPair"

  subnet_id          = aws_subnet.private.id
  security_groups    = [aws_security_group.New_DB_SG.id]

  tags = {
      Name = "New_Priv_DB_Instance"
  }
}
#do not forget  elastic ip for the ec2 in the public subnet
#and s3&ssm role for ec2 