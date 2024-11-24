module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr_block

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Environment = var.environment
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.31"
  cluster_endpoint_public_access  = true
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {
    nodeGroup = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]
      desired_size = var.number_of_nodes
      max_size     = var.max_number_of_nodes
      min_size     = var.min_number_of_nodes
    }
  }
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = var.environment
  }
}

data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

resource "kubernetes_deployment" "nginx" {
  depends_on = [
    module.eks,  # Ensure the EKS module is fully deployed, including node groups
  ]
  metadata {
    name = "nginx-deployment"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  depends_on = [
    kubernetes_deployment.nginx,  # Ensure the Deployment is created first
    module.eks,                   # Ensure the EKS module is fully deployed, including node groups
  ]
  metadata {
    name = "nginx-service"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}
