
// 查看查询结构是否正确 **tf plan 就可以看
output "aws_ami_info" {
  value = module.myapp-webserver.aws_ami_info
}

output "instance_public_ip" {
  value = module.myapp-webserver.instance_public_ip
}

output "aws_ami_info_obj" {
  value = module.myapp-webserver.aws_ami_info_obj
}
