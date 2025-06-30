# LoxiLB Open5gs testbed in AWS EKS with Terraform

This repository automates the provisioning of a complete LoxiLB-Open5gs testbed setup using Terraform, including:

* Two EKS clusters (cluster1, cluster2)
* A shared VPC
* A bastion host running LoxiLB
* UPF and UERANSIM setup with SSH provisioners
* Open5gs Helm chart deployment to EKS
* IAM access configuration for `kubectl` support

---

## Project Structure

```
.
├── main.tf                       # EKS clusters, IAM, VPC, variables
├── loxilb.tf                     # Bastion host with Docker & LoxiLB
├── gnb-ue.tf                     # UE/gnb node with UERANSIM
├── open5gs.tf                    # Open5gs Helm deployment
├── outputs.tf                    # output definition
├── upf1.tf                       # Open5gs UPF host
├── upf2.tf                       # Open5gs UPF host
├── modules/
│   └── wait/                     # Custom module to wait for user_data completion
├── output/                       # Rendered template files (ignored in Git)
├── files/                        # Template source files (e.g. gnb.conf.tpl)
├── scripts/
│   └── setup-eks-iam-access.sh   # Get EKS IAM access local
├── terraform.tfvars              # Terraform input variables (not versioned)
├── variables.tf                  # Variables definition
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/backguynn/terraform-loxilb-open5gs.git
cd terraform-loxilb-open5gs
```

### 2. Define AWS credentials

Either configure them via:

```bash
aws configure
```

Or export them manually:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### 3. Create your `terraform.tfvars`

```hcl
aws_region = "ap-northeast-3"
key_name   = "your-ec2-key-name"
user_name  = "your-iam-user"
aws_id     = "123456789012" # your AWS account ID
ssh_private_key_path = "~/.ssh/your-key.pem"
```

**Note:** This file is ignored by `.gitignore`.

---

## Usage

### Initialize Terraform

```bash
make init
```

### Apply infrastructure (including helm deployment)

```bash
make apply
```

### Destroy infrastructure

```bash
make destroy
```

---

## Notes

* `terraform.tfstate` is not tracked by Git. Remote backend is recommended for production use.
* Helm deployment depends on proper `kubectl` configuration.
* `scripts/deploy-helm.sh` assumes the clusters are reachable and contexts are named correctly.
* `local_file` and `templatefile()` functions render config files dynamically using instance metadata.

---

## Packaging

To zip this repo (excluding state and cache):

```bash
make zip
```

---
