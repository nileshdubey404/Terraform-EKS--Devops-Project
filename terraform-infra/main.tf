module "networking" {
  source = "./modules/networking"

  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr_block = var.vpc_cidr_block
  vpc_name       = var.vpc_name

  public_subnet_cidr_block  = var.public_subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block

  ap_availability_zone = var.ap_availability_zone
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

############################ Security Groups ##########################

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment
  admin_cidr   = var.admin_cidr
}


########################### Jenkins EC2 Instance ##########################

module "jenkins" {
  source = "./modules/jenkins-ec2"

  project_name = var.project_name
  environment  = var.environment

  jenkins_ami_id        = var.jenkins_ami_id
  jenkins_instance_type = var.jenkins_instance_type
  jenkins_key_name      = var.jenkins_key_name

  # Networking output → Jenkins input
  public_subnet_id = module.networking.public_subnet_ids[0]

  # Security Group output → Jenkins input
  jenkins_security_group_id = module.security_groups.jenkins_security_group_id

  # IAM output → Jenkins input
  jenkins_instance_profile_name = module.iam.jenkins_instance_profile_name
}

# ============================================================
# IAM MODULE
# ============================================================

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment

  ecr_repository_arns = [module.ecr.frontend_repository_arn]
}



################################ EKS CLUSTER ####################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  # IAM Roles for Service Accounts (not used: workloads use EKS Pod Identity)
  enable_irsa = false

  # The API endpoint is private-only; Jenkins (inside the VPC) reaches it via
  # the security group rule below.
  endpoint_public_access  = false
  endpoint_private_access = true

  # Allow the identity running Terraform to administer the cluster.
  enable_cluster_creator_admin_permissions = true

  # EKS cluster add-ons
  addons = {
    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  # Managed worker nodes
  eks_managed_node_groups = {
    node_group = {
      name           = "demo-eks-workers"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 6
      desired_size = 2
    }
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# ============================================================
# ALLOW JENKINS -> EKS API (443)
# The EKS API endpoint is private, and the cluster security group does not
# allow Jenkins by default, so kubectl/helm would time out without this.
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "jenkins_to_eks_api" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = module.security_groups.jenkins_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Jenkins to EKS API server"
}

# ============================================================
# EKS ACCESS ENTRY FOR JENKINS
# ============================================================

resource "aws_eks_access_entry" "jenkins_access_entry" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.jenkins_role_arn

  type = "STANDARD"
  depends_on = [
    module.eks
  ]
}
# The AWS provider currently supports aws_eks_access_entry with cluster_name, principal_arn, 
# type, and optional Kubernetes groups

# ============================================================
# EKS ACCESS POLICY FOR JENKINS
# ============================================================

resource "aws_eks_access_policy_association" "jenkins_access_policy_association_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.jenkins_role_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.jenkins_access_entry
  ]
}

######################### AWS LOAD BALANCER CONTROLLER POD IDENTITY ASSOCIATION #########################

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"

  role_arn = module.iam.aws_load_balancer_controller_role_arn

  depends_on = [
    module.eks
  ]
}