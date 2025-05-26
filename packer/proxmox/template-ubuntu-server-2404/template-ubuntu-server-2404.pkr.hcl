## Ubuntu Server Template
################################################################
## Packer Template to create an Ubuntu Server 24.04 template on Proxmox
packer {
  required_plugins {
    name = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

## Variable Definitions
#######################
variable "proxmox_api_url" {
    type = string
    description = "URL for the Proxmox API"
    sensitive = true
}

variable "proxmox_api_token_id" {
    type = string
    description = "Proxmox API Token ID in the format 'user@realm!tokenid'"
    sensitive = true
}

variable "proxmox_api_token_secret" {
    type = string
    description = "Proxmox API Token Secret"
    sensitive = true
}

variable "proxmox_node" {
    type = string
    description = "Proxmox node where the VM will be created"
}

variable "iso_file" {
    type = string
    description = "Path to the ISO file for the Ubuntu Server installation"
    default = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
}

variable "iso_checksum" {
    type = string
    description = "Checksum for the ISO file"
    default = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
}

variable "ssh_username" {
    type = string
    description = "SSH username for the VM"
}

variable "ssh_private_key_file" {
    type = string
    description = "Path to the private key file used to SSH to the VM"
}

## Source for VM template
#########################
source "proxmox-iso" "template-ubuntu-server-2404" {
    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    insecure_skip_tls_verify = true

    # VM General Settings
    node = var.proxmox_node
    vm_id = 802
    vm_name = "template-ubuntu-server-2404"
    template_description = "Packer Ubuntu Server template with SSH and base packages pre-configured"

    # VM OS Settings
    boot_iso {
        type = "ide"
        iso_file = var.iso_file
        unmount = true
        iso_checksum = var.iso_checksum
    }
    
    # Explicitly set boot order to prefer scsi0 (installed disk) over ide devices
    boot = "order=ide0;scsi0;net0;"

    # VM System Settings
    qemu_agent = true

    # VM Disk Settings
    scsi_controller = "virtio-scsi-single"

    disks {
        disk_size = "10G"
        format = "qcow2"
        storage_pool = "Proxmox-VMs"
        type = "scsi"
        ssd = true
    }

    # VM CPU Settings
    sockets = 1
    cores = 1

    # VM Memory Settings
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = false
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local"

    # Cloud-init config via additional ISO
    additional_iso_files {
        type = "ide"
        index = 1
        iso_storage_pool = "local"
        unmount = true
        cd_files = [
            "./cloud-init/meta-data",
            "./cloud-init/user-data",
        ]
        cd_label = "cidata"
    }

    # Packer Boot Commands
    boot_wait = "10s"
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        " autoinstall quiet ds=nocloud;s=/cdrom/",
        "<f10><wait>",
    ]

    # Allow Packer to SSH into the VM to complete provisioning
    ssh_username = var.ssh_username
    ssh_private_key_file = var.ssh_private_key_file

    # Raise the timeout for SSH
    ssh_timeout = "30m"
}

## Build Configuration
######################
build {
    name = "template-ubuntu-server-2404"
    sources = ["source.proxmox-iso.template-ubuntu-server-2404"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo sync"
        ]
    }
}