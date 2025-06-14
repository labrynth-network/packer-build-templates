# packer-build-templates

Packer template definitions for rapid infrastructure deployment.

## Packer Templates

This repository contains Packer template definitions used to build base VM images/templates optimized for automated infrastructure deployment and configuration using tools like Terraform and Ansible.

## Repository Structure

```
├── proxmox/
│   ├── template-ubuntu-noble/		   
│   │   ├── files/ 				           
│   │   ├── templates/				       
│   │	│    ├── meta-data.TEMPLATE
│   │	│    ├── user-data.TEMPLATE
│   │	│    ├── secrets.TEMPLATE.pkrvars.hcl
│   │	│    └── variables.TEMPLATE.pkrvars.hcl
│   │   └── template-ubuntu-noble.pkr.hcl	         
│   └── global.secrets.TEMPLATE.pkrvars.hcl      
├── aws/
```
- Templates are organized based on the platform they are for and then by the actual template definition. (Ex: `proxmox/template-ubuntu-noble/`)
- Each template directory contains files with values that must be populated to complete the build, such as those included in `templates/`
- The actual template definition is declared in the `<template-name>.pkr.hcl` file.

## Variables & Secrets Setup

Included with the template definitions are `variables.TEMPLATE.pkrvars.hcl` and `secrets.TEMPLATE.pkrvars.hcl`. These files are used by Packer to inject values into the build. To configure the variables in these files, simply copy the file, rename it to `variables.pkrvars.hcl` or `secrets.pkrvars.hcl` and add the values. Templates for both variables and secrets are included to provide a way to organize values by sensitivity, but it is not necessary to use `secrets.pkrvars.hcl` if you find it easier to use only `variables.pkrvars.hcl`.

### Global Variables & Secrets

For some plugins, a set of global variables can be defined for values that are reused across builds. For example, all Proxmox template definitions can use the same variables in `global.secrets.pkrvars.hcl` below:

```python
proxmox_api_url =  "https://proxmox.example.com:8006/api2/json"
proxmox_api_token_id =  "root@pam!tokenid"
proxmox_api_token_secret =  "PROXMOX_API_TOKEN_SECRET"
```

## Building an Image

### Initialize Template

Navigate to the directory of the template you would like to build and run the following command:

```bash
packer init .
```

### Validate Config

A Packer config can be validated using the following command:

```bash
packer validate \
--var-file=../global.secrets.pkrvars.hcl \
--var-file="variables.pkrvars.hcl" \
--var-file="secrets.pkrvars.hcl" \
template-ubuntu-noble.pkr.hcl
```

### Build Image

A Packer image can be built from the config using the following command:

```bash
packer build \
--var-file=../global.secrets.pkrvars.hcl \
--var-file="variables.pkrvars.hcl" \
--var-file="secrets.pkrvars.hcl" \
template-ubuntu-noble.pkr.hcl
```
