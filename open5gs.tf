
locals {
  cluster1_helm_values_file = templatefile("${path.module}/files/helm_values.yaml.tpl", {
    upf_public_ip = aws_instance.upf_instance_1.private_ip
  })
  cluster1_helm_smf_config_file = templatefile("${path.module}/files/smf-config.yaml.tpl", {
    smf_subnet = var.cluster1_smf_subnet
  })
  cluster2_helm_values_file = templatefile("${path.module}/files/helm_values.yaml.tpl", {
    upf_public_ip = aws_instance.upf_instance_2.private_ip
  })
  cluster2_helm_smf_config_file = templatefile("${path.module}/files/smf-config.yaml.tpl", {
    smf_subnet = var.cluster2_smf_subnet
  })
}

resource "local_file" "rendered_cluster1_helm_values" {
  content  = local.cluster1_helm_values_file
  filename = "${path.root}/output/cluster1_helm_values.yaml"
}

resource "local_file" "rendered_cluster1_smf_config" {
  content  = local.cluster1_helm_smf_config_file
  filename = "${path.root}/output/cluster1_smf_config.yaml"
}
resource "local_file" "rendered_cluster2_helm_values" {
  content  = local.cluster2_helm_values_file
  filename = "${path.root}/output/cluster2_helm_values.yaml"
}

resource "local_file" "rendered_cluster2_smf_config" {
  content  = local.cluster2_helm_smf_config_file
  filename = "${path.root}/output/cluster2_smf_config.yaml"
}

resource "null_resource" "helm_install" {
  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME    = module.eks_cluster_1.cluster_name
      REGION          = var.aws_region
      AWS_ACCOUNT_ID  = var.aws_id
      USER_NAME       = var.user_name
    }

    command = <<-EOT
      echo "Installing Helm chart on EKS Cluster 1"
      git clone https://github.com/backguynn/open5gs-helm-repo.git
      cp ${local_file.rendered_cluster1_smf_config.filename} \
        ./open5gs-helm-repo/open5gs-helm-charts/templates/smf-configmap.yaml
      kubectl create ns open5gs \
        --context ${module.eks_cluster_1.cluster_name}
      helm -n open5gs upgrade --install core5g ./open5gs-helm-repo/open5gs-helm-charts \
        --values ${local_file.rendered_cluster1_helm_values.filename} \
        --kube-context ${module.eks_cluster_1.cluster_name}
      echo "Helm chart installed on EKS Cluster 1"
      echo "--------------------------------------------------"
      echo "Installing Helm chart on EKS Cluster 2"
      cp ${local_file.rendered_cluster2_smf_config.filename} \
        ./open5gs-helm-repo/open5gs-helm-charts/templates/smf-configmap.yaml
      kubectl create ns open5gs \
        --context ${module.eks_cluster_2.cluster_name}
      helm -n open5gs upgrade --install core5g ./open5gs-helm-repo/open5gs-helm-charts \
        --values ${local_file.rendered_cluster2_helm_values.filename} \
        --kube-context ${module.eks_cluster_2.cluster_name}
      echo "Helm chart installed on EKS Cluster 2"
    EOT
  }

  # Ensure this runs after both EKS clusters are created
  depends_on = [
    null_resource.run_after_eks_cluster1,
    null_resource.run_after_eks_cluster2,
    null_resource.configure_upf_1,
    null_resource.configure_upf_2,
    local_file.rendered_cluster1_helm_values,
    local_file.rendered_cluster2_helm_values,
    local_file.rendered_cluster1_smf_config,
    local_file.rendered_cluster2_smf_config
  ]
}