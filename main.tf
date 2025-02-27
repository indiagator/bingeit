provider "aws" {
  region = "ap-south-1"  # Change to your preferred region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "docdb-vpc"
  }
}

# Public Subnet for Bastion
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create subnets in different AZs
resource "aws_subnet" "docdb_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"  # Adjust CIDR block according to your VPC
  availability_zone = "ap-south-1b"

  tags = {
    Name = "docdb-subnet-1"
  }
}

resource "aws_subnet" "docdb_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"  # Adjust CIDR block according to your VPC
  availability_zone = "ap-south-1c"

  tags = {
    Name = "docdb-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Security Group for DocumentDB
resource "aws_security_group" "docdb" {
  name        = "docdb-sg"
  description = "Security group for DocumentDB cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docdb-sg"
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami           = "ami-0c2af51e265bd5e0e"
  instance_type = "t3.micro"
  key_name      = "lone1connect"     # Replace with your key pair name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }
}

# Create DocumentDB subnet group
resource "aws_docdb_subnet_group" "docdb" {
  name        = "docdb-subnet-group"
  description = "DocumentDB subnet group"
  subnet_ids  = [aws_subnet.docdb_subnet_1.id, aws_subnet.docdb_subnet_2.id]

  tags = {
    Name = "docdb-subnet-group"
  }
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "default" {
  cluster_identifier     = "docdb-cluster"
  engine                = "docdb"
  master_username       = "indiagator"
  master_password       = "indiagator"  # Change this to a secure password
  skip_final_snapshot   = true
  db_subnet_group_name  = aws_docdb_subnet_group.docdb.name
  vpc_security_group_ids = [aws_security_group.docdb.id]

  tags = {
    Name = "docdb-cluster"
  }
}

# DocumentDB Cluster Instance
resource "aws_docdb_cluster_instance" "cluster_instances" {
  identifier         = "docdb-cluster-instance"
  cluster_identifier = aws_docdb_cluster.default.id
  instance_class     = "db.t3.medium"
}

# Output values
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "docdb_endpoint" {
  value = aws_docdb_cluster.default.endpoint
}
