# CONFIGURA LA VPC CON SU BLOQUE CIDR Y LOS SERVICIOS DNS HABILITADOS.
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.nombre_proyecto}-vpc" }
}

# OBTIENE TRES ZONAS DE DISPONIBILIDAD DE AWS.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  zonas = slice(data.aws_availability_zones.available.names, 0, 3)
}

# CREA Y ASOCIA UN INTERNET GATEWAY A LA VPC.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.nombre_proyecto}-igw" }
}

# CREA TRES SUBREDES PÚBLICAS EN LA VPC.
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = local.zonas[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.nombre_proyecto}-publica-${count.index + 1}" }
}

# CREA TRES SUBREDES PRIVADAS EN LA VPC.
resource "aws_subnet" "private" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, (count.index + 1) * 10)
  availability_zone       = local.zonas[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.nombre_proyecto}-privada-${count.index + 1}" }
}

# CREA TRES NAT GATEWAYS CON SUS DIRECCIONES IP PÚBLICAS.
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
  tags   = { Name = "${var.nombre_proyecto}-eip-${count.index + 1}" }
}
resource "aws_nat_gateway" "nat" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${var.nombre_proyecto}-nat-${count.index + 1}" }
}

# CREA UNA TABLA DE RUTAS PÚBLICA Y LA ASOCIA A LAS TRES SUBREDES.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.nombre_proyecto}-publica" }
}
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# CONFIGURA LAS TABLAS DE RUTAS DE LAS TRES SUBREDES PRIVADAS.
resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "${var.nombre_proyecto}-privada-${count.index + 1}" }
}
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
