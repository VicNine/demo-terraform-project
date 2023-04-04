<!-- @format -->

# Demo terraform project from nana's tf course

> _Please do setup the `.tfvars` file and before use_

## Commands

```
terraform init
terraform plan -var-file filename.tfvars
terraform run -var-file filename.tfvars --auto-approve
```

**module 的核心是把 resources 集合/抽象成完整的逻辑单元**

所以一两个 resource 合并成一个 module 是不可取的，至少3-4个
