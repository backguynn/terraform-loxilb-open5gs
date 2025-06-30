data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "loxilb_sg" {
  name        = "loxilb-sg"
  description = "Allow all traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "loxilb-sg"
  }
}

resource "aws_security_group_rule" "eks1_allow_loxilb_ssh" {
  type                     = "ingress"
  from_port               = 22
  to_port                 = 22
  protocol                = "tcp"
  security_group_id       = module.eks_cluster_1.node_security_group_id
  source_security_group_id = aws_security_group.loxilb_sg.id
}

resource "aws_security_group_rule" "eks2_allow_loxilb_ssh" {
  type                     = "ingress"
  from_port               = 22
  to_port                 = 22
  protocol                = "tcp"
  security_group_id       = module.eks_cluster_2.node_security_group_id
  source_security_group_id = aws_security_group.loxilb_sg.id
}

resource "aws_instance" "loxilb_host" {
  ami                    = data.aws_ami.ubuntu22.id
  instance_type          = "t3.large"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.loxilb_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update -y
    apt install -y docker-ce

    systemctl enable docker
    systemctl start docker

    docker run -u root --cap-add SYS_ADMIN --restart unless-stopped --privileged -dit -v /dev/log:/dev/log \
      --entrypoint=/root/loxilb-io/loxilb/loxilb --net=host --name loxilb ghcr.io/loxilb-io/loxilb:scp
  EOF

  tags = {
    Name = "loxilb-host"
  }
}

resource "null_resource" "configure_kubeconfig_cluster1" {
  depends_on = [module.eks_cluster_1]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ap-northeast-3 --name eks-cluster-1 --alias eks-cluster-1"
  }
}

resource "null_resource" "configure_kubeconfig_cluster2" {
  depends_on = [module.eks_cluster_2]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ap-northeast-3 --name eks-cluster-2 --alias eks-cluster-2"
  }
}

locals {
  kube_loxilb_manifest = templatefile("${path.module}/files/kube-loxilb.yaml.tpl", {
    loxilb_ip = aws_instance.loxilb_host.private_ip
  })
}

resource "local_file" "rendered_kube_loxilb" {
  content  = local.kube_loxilb_manifest
  filename = "${path.module}/output/rendered-kube-loxilb.yaml"
}

resource "null_resource" "apply_kube_loxilb" {
  depends_on = [
    local_file.rendered_kube_loxilb, 
    null_resource.configure_kubeconfig_cluster1, 
    null_resource.run_after_eks_cluster1, 
    null_resource.run_after_eks_cluster2
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting manifest deployment"
      kubectl apply --context ${module.eks_cluster_1.cluster_name} -f ${path.module}/files/kube-loxilb-clusterRole.yaml
      kubectl apply --context ${module.eks_cluster_1.cluster_name} -f ${path.module}/output/rendered-kube-loxilb.yaml
      kubectl apply --context ${module.eks_cluster_2.cluster_name} -f ${path.module}/files/kube-loxilb-clusterRole.yaml
      kubectl apply --context ${module.eks_cluster_2.cluster_name} -f ${path.module}/output/rendered-kube-loxilb.yaml
      echo "Deployment complete"
    EOT
  }
}

output "loxilb_public_ip" {
  value = aws_instance.loxilb_host.public_ip
}

output "loxilb_private_ip" {
  value = aws_instance.loxilb_host.private_ip
}



