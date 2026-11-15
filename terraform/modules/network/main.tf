
# VPC

# Red principal donde se crean todos los recursos del proyecto.
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.nombre_proyecto}-vpc"
  }
}

# INTERNET GATEWAY

# Permite que las subredes publicas tengan salida a Internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.nombre_proyecto}-igw"
  }
}

# SUBREDES PUBLICAS

# Una subred publica en cada zona de disponibilidad.
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_subred_publica_az1
  availability_zone       = var.zona_disponibilidad_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.nombre_proyecto}-public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_subred_publica_az2
  availability_zone       = var.zona_disponibilidad_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.nombre_proyecto}-public-az2"
  }
}

# SUBREDES DE APLICACION

# Las instancias APP y K3s funcionan en estas subredes privadas.
resource "aws_subnet" "app_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_subred_app_az1
  availability_zone = var.zona_disponibilidad_1

  tags = {
    Name = "${var.nombre_proyecto}-app-az1"
  }
}

resource "aws_subnet" "app_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_subred_app_az2
  availability_zone = var.zona_disponibilidad_2

  tags = {
    Name = "${var.nombre_proyecto}-app-az2"
  }
}

# SUBREDES DE BASE DE DATOS

# RDS utiliza subredes privadas sin salida directa a Internet.
resource "aws_subnet" "db_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_subred_bd_az1
  availability_zone = var.zona_disponibilidad_1

  tags = {
    Name = "${var.nombre_proyecto}-db-az1"
  }
}

resource "aws_subnet" "db_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_subred_bd_az2
  availability_zone = var.zona_disponibilidad_2

  tags = {
    Name = "${var.nombre_proyecto}-db-az2"
  }
}

# DIRECCIONES IP PARA NAT

# Reservamos una IP publica para cada NAT Gateway.
resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name = "${var.nombre_proyecto}-eip-nat-az1"
  }
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name = "${var.nombre_proyecto}-eip-nat-az2"
  }
}

# NAT GATEWAYS

# Cada zona tiene su propio NAT para la salida de las subredes APP.
resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.nombre_proyecto}-nat-az1"
  }
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.nombre_proyecto}-nat-az2"
  }
}

# RUTAS PUBLICAS

# El trafico hacia Internet sale por el Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.nombre_proyecto}-rt-public"
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

# RUTAS APP AZ1

# La subred APP de AZ1 utiliza el NAT de su misma zona.
resource "aws_route_table" "app_az1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }

  tags = {
    Name = "${var.nombre_proyecto}-rt-app-az1"
  }
}

resource "aws_route_table_association" "app_az1" {
  subnet_id      = aws_subnet.app_az1.id
  route_table_id = aws_route_table.app_az1.id
}

# RUTAS APP AZ2

# La subred APP de AZ2 utiliza el segundo NAT Gateway.
resource "aws_route_table" "app_az2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2.id
  }

  tags = {
    Name = "${var.nombre_proyecto}-rt-app-az2"
  }
}

resource "aws_route_table_association" "app_az2" {
  subnet_id      = aws_subnet.app_az2.id
  route_table_id = aws_route_table.app_az2.id
}

# RUTAS BASE DE DATOS

# La base de datos solo necesita comunicacion dentro de la VPC.
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.nombre_proyecto}-rt-db"
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
