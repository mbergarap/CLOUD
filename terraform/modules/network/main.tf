# =========================
# VPC
# =========================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# =========================
# INTERNET GATEWAY
# =========================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# =========================
# SUBREDES PUBLICAS
# =========================

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-az2"
  }
}

# =========================
# SUBREDES PRIVADAS APP
# =========================

resource "aws_subnet" "app_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_az1_cidr
  availability_zone = var.az1

  tags = {
    Name = "${var.project_name}-app-az1"
  }
}

resource "aws_subnet" "app_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_az2_cidr
  availability_zone = var.az2

  tags = {
    Name = "${var.project_name}-app-az2"
  }
}

# =========================
# SUBREDES PRIVADAS DB
# =========================

resource "aws_subnet" "db_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_az1_cidr
  availability_zone = var.az1

  tags = {
    Name = "${var.project_name}-db-az1"
  }
}

resource "aws_subnet" "db_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_az2_cidr
  availability_zone = var.az2

  tags = {
    Name = "${var.project_name}-db-az2"
  }
}

# =========================
# ELASTIC IP NAT
# =========================

resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-nat-az1"
  }
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-nat-az2"
  }
}

# =========================
# NAT GATEWAYS
# =========================

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-az1"
  }
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-az2"
  }
}

# =========================
# ROUTE TABLE PUBLICA
# =========================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# =========================
# ROUTE TABLE APP AZ1
# =========================

resource "aws_route_table" "app_az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }

  tags = {
    Name = "${var.project_name}-rt-app-az1"
  }
}

resource "aws_route_table_association" "app_az1" {
  subnet_id      = aws_subnet.app_az1.id
  route_table_id = aws_route_table.app_az1.id
}

# =========================
# ROUTE TABLE APP AZ2
# =========================

resource "aws_route_table" "app_az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2.id
  }

  tags = {
    Name = "${var.project_name}-rt-app-az2"
  }
}

resource "aws_route_table_association" "app_az2" {
  subnet_id      = aws_subnet.app_az2.id
  route_table_id = aws_route_table.app_az2.id
}

# =========================
# ROUTE TABLE DB
# =========================

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rt-db"
  }
}

resource "aws_route_table_association" "db_az1" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_az2" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.db.id
}