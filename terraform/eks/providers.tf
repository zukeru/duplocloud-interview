terraform {
  required_version = ">= 1.3.3"
  backend "s3" {
    bucket         = "dupulo-cloud-interview"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "dupulo-cloud-interview"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
