provider "aws" {
  region = "ap-northeast-3"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "eks-shared-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  map_public_ip_on_launch = true

  tags = {
    Project = "shared-eks"
  }
}

data "aws_availability_zones" "available" {}

module "eks_cluster_1" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.37.1"

  cluster_name                   = "eks-cluster-1"
  cluster_version                = "1.29"
  control_plane_subnet_ids       = module.vpc.private_subnets
  subnet_ids                     = slice(module.vpc.public_subnets, 0, 2)
  vpc_id                         = module.vpc.vpc_id

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
  }

  tags = {
    Cluster = "eks-cluster-1"
  }
}

module "eks_cluster_2" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.37.1"

  cluster_name    = "eks-cluster-2"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
  }

  tags = {
    Cluster = "eks-cluster-2"
  }
}

resource "aws_security_group_rule" "eks1_allow_all_inbound" {
  type                     = "ingress"
  from_port               = 0
  to_port                 = 0
  protocol                = "-1"
  cidr_blocks             = ["0.0.0.0/0"]
  security_group_id       = module.eks_cluster_1.node_security_group_id
}

resource "aws_security_group_rule" "eks2_allow_all_inbound" {
  type                     = "ingress"
  from_port               = 0
  to_port                 = 0
  protocol                = "-1"
  cidr_blocks             = ["0.0.0.0/0"]
  security_group_id       = module.eks_cluster_2.node_security_group_id
}

# null_resource to run shell script locally after EKS Cluster1 is created
resource "null_resource" "run_after_eks_cluster1" {
  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME    = module.eks_cluster_1.cluster_name
      REGION          = var.aws_region
      AWS_ACCOUNT_ID  = var.aws_id
      USER_NAME       = var.user_name
    }

    # Replace with the path to your local shell script
    command = "sh ./scripts/setup-eks-iam-access.sh"
  }

  # Triggers to ensure this runs after the EKS module
  triggers = {
    cluster_name = module.eks_cluster_1.cluster_name
    cluster_id   = module.eks_cluster_1.cluster_id
  }

  # Ensure the null_resource depends on the EKS module to run after its creation
  depends_on = [module.eks_cluster_1]
}

# null_resource to run shell script locally after EKS Cluster2 is created
resource "null_resource" "run_after_eks_cluster2" {
  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME    = module.eks_cluster_2.cluster_name
      REGION          = var.aws_region
      AWS_ACCOUNT_ID  = var.aws_id
      USER_NAME       = var.user_name
    }

    # Replace with the path to your local shell script
    command = "sh ./scripts/setup-eks-iam-access.sh"
  }

  # Triggers to ensure this runs after the EKS module
  triggers = {
    cluster_name = module.eks_cluster_2.cluster_name
    cluster_id   = module.eks_cluster_2.cluster_id
  }

  # Ensure the null_resource depends on the EKS module to run after its creation
  depends_on = [module.eks_cluster_2]
}
