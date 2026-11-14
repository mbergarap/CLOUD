# =========================
# KEY PAIR
# =========================

resource "aws_key_pair" "bastion_key" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-key"
  }
}

# =========================
# BASTION HOST
# =========================

resource "aws_instance" "bastion" {
  # AMI fija para evitar que Terraform reemplace el bastion
  # cada vez que AWS publique una nueva Amazon Linux 2023.
  ami           = var.ami_id
  instance_type = "t3.micro"

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [
    var.bastion_sg_id
  ]

  key_name = aws_key_pair.bastion_key.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}