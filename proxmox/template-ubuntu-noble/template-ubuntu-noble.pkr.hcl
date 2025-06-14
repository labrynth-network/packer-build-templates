## Ubuntu Server Noble (24.04.x) Template
################################################################################### 
## Packer Definition to create an Ubuntu Server (Noble 24.04.x) Template on Proxmox

packer {
  required_plugins {
    name = {
      version = "~> 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

## Variable Definitions
#######################
variable "proxmox_api_url" {
    type = string
    description = "Proxmox API URL, e.g., https://proxmox.example.com:8006/api2/json"
    sensitive = true
}

variable "proxmox_api_token_id" {
    type = string
    description = "Proxmox API token ID, e.g., root@pam!packer"
    sensitive = true
}

variable "proxmox_api_token_secret" {
    type = string
    description = "Proxmox API token secret"
    sensitive = true
}

variable "proxmox_node" {
    type = string
    description = "Proxmox node where the VM will be created"
}

variable "ssh_username" {
    type = string
    description = "SSH username for Packer SSH communicator"
    default = "packer"
}

variable "ssh_private_key_file" {
    type = string
    description = "Path to the SSH private key file for Packer SSH communicator"
    default = "~/.ssh/id_rsa"
}

variable "http_bind_address" {
    type = string
    description = "HTTP bind address for Packer HTTP server"
    default = "0.0.0.0"
}

variable "http_port" {
    type = number
    description = "HTTP port for Packer HTTP server"
    default = 8802
}

## Resource Definiation for the VM Template
###########################################
source "proxmox-iso" "template-ubuntu-noble" {

    # Proxmox Connection Settings
    proxmox_url              = var.proxmox_api_url
    username                 = var.proxmox_api_token_id
    token                    = var.proxmox_api_token_secret
    insecure_skip_tls_verify = true

    # VM General Settings
    node                 = var.proxmox_node
    vm_id                = "802"
    vm_name              = "template-ubuntu-noble"
    template_description = "Ubuntu Server Noble (24.04) Template"

    # VM OS Settings
    boot_iso {
        type         = "ide"
        iso_file     = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
        unmount      = true
        iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    }

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-single"

    disks {
        disk_size    = "20G"
        format       = "raw"
        storage_pool = "Proxmox-VMs"
        type         = "scsi"
        ssd          = true
    }

    # VM CPU Settings
    sockets = "1"
    cores   = "1"

    # VM Memory Settings
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model    = "virtio"
        bridge   = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init              = true
    cloud_init_storage_pool = "Proxmox-VMs"

    # Packer Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]

    boot      = "c"
    boot_wait = "20s"

    # Packer HTTP Autoinstall Settings
    http_directory    = "http"
    http_bind_address = var.http_bind_address
    http_port_min     = var.http_port
    http_port_max     = var.http_port
    

    # Packer SSH Communicator Settings
    communicator         = "ssh"
    ssh_username         = var.ssh_username
    ssh_private_key_file = var.ssh_private_key_file
    ssh_timeout          = "30m"
}

## Build Definition to create the VM Template
#############################################
build {

    name    = "template-ubuntu-noble"
    sources = ["source.proxmox-iso.template-ubuntu-noble"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}