resource "aws_instance" "ue_instance" {
  ami                    = data.aws_ami.ubuntu22.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.loxilb_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = "ue-instance"
  }
}

locals {
  gnb_conf_rendered = templatefile("${path.module}/files/gnb.conf.tpl", {
    gnb_address = aws_instance.ue_instance.private_ip
    amf_service_ip = aws_instance.loxilb_host.private_ip
  })
  ue_conf_rendered = templatefile("${path.module}/files/ue.conf.tpl", {
    gnb_address = aws_instance.ue_instance.private_ip
  })
}

resource "local_file" "rendered_gnb_conf" {
  content  = local.gnb_conf_rendered
  filename = "${path.root}/output/rendered-gnb.conf"
}

resource "local_file" "rendered_ue_conf" {
  content  = local.ue_conf_rendered
  filename = "${path.root}/output/rendered-ue.conf"
}

resource "null_resource" "copy_gnb_conf" {
  depends_on = [
    aws_instance.ue_instance, 
    local_file.rendered_gnb_conf,
    local_file.rendered_ue_conf
  ]

  connection {
    type        = "ssh"
    host        = aws_instance.ue_instance.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = local_file.rendered_gnb_conf.filename
    destination = "/tmp/gnb.conf"
  }

  provisioner "file" {
    source      = local_file.rendered_ue_conf.filename
    destination = "/tmp/ue.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing UERANSIM...'",
      "sudo apt update",
      "sudo apt install -y software-properties-common",
      "sudo add-apt-repository -y universe",
      "sudo apt update",
      "sudo apt install -y git make gcc g++ libsctp-dev lksctp-tools iproute2",
      "git clone https://github.com/aligungr/UERANSIM",
      "sudo snap install cmake --classic",
      "cd ~/UERANSIM && make",
      "sudo mv /tmp/gnb.conf /home/ubuntu/UERANSIM/gnb.conf",
      "sudo mv /tmp/ue.conf /home/ubuntu/UERANSIM/ue.conf"
    ]
  }
}