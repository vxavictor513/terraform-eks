# Ref:
# 1. https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
# 2. https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v14.0.0/examples/irsa/irsa.tf

locals {
  cluster_name                      = var.eks_cluster_name
  k8s_service_account_namespace     = "kube-system"
  external_dns_service_account_name = "external-dns"
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.9.0"
  create_role                   = true
  role_name                     = "external_dns"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.external_dns_service_account_name}"]

  tags = local.common_tags
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "external_dns"
  description = "EKS ExternalDNS policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.external_dns.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"] //TODO
  }
}

