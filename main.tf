terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13"
    }
  }
  backend "s3" {
    bucket = "ies-asean-terraform-state-bucket"
    key    = "wailoon/eks.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.vpc.id
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "dev"
    Created_By  = "wai.loon.theng"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "wl-cluster"
  cluster_version = "1.19"
  subnets         = data.aws_subnet_ids.subnets.ids
  vpc_id          = data.aws_vpc.vpc.id

  worker_groups = [
    {
      instance_type    = "m4.large"
      root_volume_type = "gp2"
      asg_max_size     = 1
    }
  ]

  map_users = var.map_users

  tags = local.common_tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
} 
