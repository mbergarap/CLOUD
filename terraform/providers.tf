# VERSIONES
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # Estado local: Terraform no requiere preparar un bucket S3 previo.
}

# PROVEEDOR AWS
# default_tags etiqueta todos los recursos que lo soportan.
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = var.nombre_proyecto
      Gestion  = "terraform"
      Materia  = "Implementacion de Soluciones Cloud"
      Ambiente = "obligatorio"
    }
  }
}
