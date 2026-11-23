# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "isc-obligatorio-vpc" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  zonas = slice(data.aws_availability_zones.available.names, 0, 3)
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "isc-obligatorio-igw" }
}

# SUBREDES PUBLICAS
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = local.zonas[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "isc-obligatorio-publica-${count.index + 1}" }
}

# SUBREDES PRIVADAS
resource "aws_subnet" "private" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, (count.index + 1) * 10)
  availability_zone       = local.zonas[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "isc-obligatorio-privada-${count.index + 1}" }
}

# ELASTIC IP Y NAT GATEWAYS
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
  tags   = { Name = "isc-obligatorio-eip-${count.index + 1}" }
}
resource "aws_nat_gateway" "nat" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "isc-obligatorio-nat-${count.index + 1}" }
}

# TABLA DE RUTAS PUBLICA
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "isc-obligatorio-publica" }
}
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# TABLAS DE RUTAS PRIVADAS
resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "isc-obligatorio-privada-${count.index + 1}" }
}
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
