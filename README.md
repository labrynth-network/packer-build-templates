# terraform-infra-automation

Terraform infrastructure definitions and templates for various platforms.

```
packer build -force \
 -var-file=variables.pkrvars.hcl \
 -var-file=../global.variables.pkrvars.hcl \
 template-ubuntu-server-2404.pkr.hcl
```
