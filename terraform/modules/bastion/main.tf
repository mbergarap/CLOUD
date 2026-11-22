
# CLAVE SSH

# Registramos la clave publica que usamos para acceder a las instancias.
resource "aws_key_pair" "bastion_key" {
  key_name   = "${var.nombre_proyecto}-key"
  public_key = file(var.ruta_clave_publica_ssh)

  tags = {
    Name = "${var.nombre_proyecto}-key"
  }
}

# BASTION

# Instancia que utilizamos para conectarnos por SSH a los servidores privados.
resource "aws_instance" "bastion" {
  # Usamos una AMI fija para evitar reemplazos al publicarse nuevas versiones.
  ami           = var.id_ami
  instance_type = "t3.micro"

  subnet_id = var.id_subred_publica

  vpc_security_group_ids = [
    var.id_sg_bastion
  ]

  key_name = aws_key_pair.bastion_key.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.nombre_proyecto}-bastion"
  }
}
