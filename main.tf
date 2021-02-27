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
    encrypt = true
    bucket  = "ies-asean-terraform-state-bucket"
    key     = "wailoon/eks.tfstate"
    region  = "ap-southeast-1"
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

data "aws_route53_zone" "selected" {
  name         = var.route53_zone
  private_zone = false
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
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.19"
  subnets         = data.aws_subnet_ids.subnets.ids
  vpc_id          = data.aws_vpc.vpc.id

  worker_groups = [
    {
      instance_type        = "m4.large"
      root_volume_type     = "gp2"
      root_encrypted       = true
      asg_desired_capacity = 0
      asg_min_size         = 0
      asg_max_size         = 1
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

resource "aws_acm_certificate" "api" {
  domain_name       = var.api_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.api_domain}"
  ]

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api_validation : record.fqdn]
}

resource "aws_route53_record" "api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

/* resource "aws_route53_zone" "api" {
  name = var.api_domain
  tags = local.common_tags
} */
