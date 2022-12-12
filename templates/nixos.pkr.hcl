variable "hcloud-servertype" {
  type    = string
  default = "cx11"
}

variable "hcloud-location" {
  type    = string
  default = "fsn1"
  /* default = "hel1" */
}

variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

variable "luks-password" {
  type      = string
  default   = "${env("LUKS_PASSWORD")}"
  sensitive = true
}

variable "nix-channel" {
  type    = string
  default = "22.11"
}

variable "nix-release" {
  type    = string
  default = "2.11.0"
}

variable "root-ssh-key" {
  type    = string
  /* default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCo31gjjKXTeVYH6Oy7xGqT7rfsBkhLOFDsDEwkfNvVP8jzobumSPfIlBVKLAYU3A+5lPlICLVfnkGSIkLO+fLb3c54HQ8GHb2R/+cq5N/JicMu7LAmYy7ADF7cwl8UklLYm9i2UrZtsD+Xi/2KeGWqpbscs6HNqOoQjoOrQHOqpJW0kaAr+IgMEL+ECh1/loS4J3cVTk9Xi+jZbNDRR8BtqZ9WEpYSftqGLNHeRTYq35kw0FkV5CKhDoKBDLyTHU/sSyic7NpIWd7MI0CzMYmb5bSAdW19KdgNbz4Y+yvZsD9LZ6rvy4MbwWXAL0f/kSKMxh7Zw57sYmgf0Q8O6LIc5cR/kzs63FChWyoIHEhbtzC0kSNatCrN6UYG/cHehUvdpQVzf5zuvlErw0C4NxYth8l5QrcwoOKQNeiRYOivyUaiKEtcVmv9KD91IPhzwCv3v6DVhfc61gmjRL/G4Ipzv61M9zGJXLfOytxQ6uZVkfIQ9em+/YqVyWV/TezprYhLVwHPZ5c9/qLvnPRidrCAJxGUdtB3LHM2swsAmx1cS8m5jxggWIBmwZB5uxCliF2XHXu0+rUmmi0sTX4EcL5HlXuzMBW3vtKVTy4kGHqvNjIQx7GGcs4Bfp3qfR893a1xrZQoOAeuLvwGDa1otAQLPsZw4nuA8XFpg0GP35bvGQ== openpgp:0xB487F34B" */
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ3eAZ+eqS9DupgFd+U/YZ4M4hv0Ft6YC1WhHMU8QuLm rti@r23"
}

locals {
  build-id = "${ uuidv4() }"
  build-labels  = {
    os-flavor              = "nixos"
    "nixos/channel"        = "${ var.nix-channel }"
    "nixos/nix.release"    = "${ var.nix-release }"
    "packer.io/build.id"   = "${ local.build-id }"
    "packer.io/build.time" = "{{ timestamp }}"
    "packer.io/version"    = "{{ packer_version }}"
  }
}

source "hcloud" "nixos" {
  server_type = "${ var.hcloud-servertype }"
  image       = "debian-11"
  rescue      = "linux64"
  location = "${ var.hcloud-location }"
  snapshot_name = "nixos-{{ timestamp }}"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = [ "source.hcloud.nixos" ]

  provisioner "shell" {
    script           = "files/filesystem.sh"
    environment_vars = [ 
      "LUKS_PASSWORD=${var.luks-password}" 
    ]
  }

  provisioner "file" {
    source      = "files/nixos/key.gpg"
    destination = "/tmp/key-${local.build-id}.gpg"
  }

  provisioner "shell" {
    inline = [
      "gpg --batch --import /tmp/key-${local.build-id}.gpg",
      "mkdir -p /mnt/etc/nixos/hcloud/",
    ]
  }

  provisioner "file" {
    source      = "files/nixos/config/"
    destination = "/mnt/etc/nixos/"
  }

  provisioner "shell" {
    script           = "files/nixos/install.sh"
    environment_vars = [
      "NIX_RELEASE=${var.nix-release}",
      "NIX_CHANNEL=${var.nix-channel}",
      "ROOT_SSH_KEY=${var.root-ssh-key}",
    ]
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
