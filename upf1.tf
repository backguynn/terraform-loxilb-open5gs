resource "aws_instance" "upf_instance_1" {
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

  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install gnupg
    curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    apt update
    apt install -y mongodb-org
    add-apt-repository --yes ppa:open5gs/latest
    apt update
    apt install -y open5gs
    systemctl stop open5gs*
    touch /tmp/setup_done
  EOF

  tags = {
    Name = "upf-instance-1"
  }
}

module "wait_for_upf1" {
  source            = "./modules/wait"
  host              = aws_instance.upf_instance_1.public_ip
  user              = "ubuntu"
  private_key_path  = var.ssh_private_key_path
  ready_file        = "/tmp/setup_done"

  depends_on = [aws_instance.upf_instance_1]
}

locals {
  upf_conf_1_rendered = templatefile("${path.module}/files/upf.yaml.tpl", {
    upf_pfcp_address = aws_instance.upf_instance_1.private_ip
    upf_gtpu_address = aws_instance.upf_instance_1.private_ip
    upf_ipv4_subnet  = "10.45.0.0/16"
    upf_ipv4_gateway = "10.45.0.1"
    upf_ipv6_subnet  = "2001:db8:cafe::/48"
    upf_ipv6_gateway = "2001:db8:cafe::1"
  })
}

resource "local_file" "rendered_upf_1_conf" {
  content  = local.upf_conf_1_rendered
  filename = "${path.module}/output/rendered-upf-1.yaml"
}

resource "null_resource" "configure_upf_1" {
  depends_on = [
    module.wait_for_upf1, 
    local_file.rendered_upf_1_conf
  ]

  connection {
    type        = "ssh"
    host        = aws_instance.upf_instance_1.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = local_file.rendered_upf_1_conf.filename
    destination = "/tmp/upf.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/upf.yaml /etc/open5gs/upf.yaml",
      "sudo systemctl restart open5gs-upfd",
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "sudo sysctl -w net.ipv6.conf.all.forwarding=1",
      "sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE",
      "sudo ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE"
    ]
  }
}