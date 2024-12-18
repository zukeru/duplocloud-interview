output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "nginx_service_hostname" {
  value = kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].hostname
}
