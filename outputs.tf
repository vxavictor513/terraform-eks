output "cluster_id" {
  value = module.eks.cluster_id
}
output "cluster_arn" {
  value = module.eks.cluster_arn
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "kubeconfig" {
  value = module.eks.kubeconfig
}
output "kubeconfig_filename" {
  value = module.eks.kubeconfig_filename
}

output "api_certificate_arn" {
  value = aws_acm_certificate_validation.api.certificate_arn
}

output "this_db_instance_address" {
  value = module.db.this_db_instance_address
}
