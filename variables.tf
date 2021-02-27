variable "eks_cluster_name" {}
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}
variable "route53_zone" {}
variable "domain" {}
variable "api_domain" {}
variable "devops_user_name" {}
