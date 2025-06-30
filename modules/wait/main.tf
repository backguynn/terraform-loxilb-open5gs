variable "host" {
  description = "Public IP or hostname of the instance"
  type        = string
}

variable "user" {
  description = "Username to use for SSH"
  type        = string
  default     = "ubuntu"
}

variable "private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "ready_file" {
  description = "Path to the 'ready' file on the remote instance"
  type        = string
  default     = "/tmp/setup_done"
}

variable "max_attempts" {
  description = "Maximum number of retries"
  type        = number
  default     = 30
}

variable "interval_seconds" {
  description = "Seconds to wait between attempts"
  type        = number
  default     = 10
}

resource "null_resource" "wait" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for ${var.ready_file} to appear on ${var.host}...'",
      "i=0; while [ ! -f ${var.ready_file} ] && [ $i -lt ${var.max_attempts} ]; do sleep ${var.interval_seconds}; i=$((i+1)); done",
      "if [ ! -f ${var.ready_file} ]; then echo 'Timeout waiting for ${var.ready_file}'; exit 1; fi",
      "echo 'Ready file ${var.ready_file} found!'"
    ]
  }
}
