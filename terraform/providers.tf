# DEFINE LAS VERSIONES DE TERRAFORM 
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

}

# ESTABLECE LA REGIÓN AWS Y LAS ETIQUETAS PREDETERMINADAS DE LOS RECURSOS.
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
