// 查看查询结构是否正确 **tf plan 就可以看
output "aws_ami_info" {
  value = "ami_id: ${data.aws_ami.latest-amazon-linux-image.id}\nami_description: ${data.aws_ami.latest-amazon-linux-image.description}"
}

# output "aws_ami_info_list" {
#   value = ["ami_id: ${data.aws_ami.latest-amazon-linux-image.id}", "ami_description: ${data.aws_ami.latest-amazon-linux-image.description}"]
# }

output "aws_ami_info_obj" {
  value = {
    "ami_id" : data.aws_ami.latest-amazon-linux-image.id,
    "ami_description" : data.aws_ami.latest-amazon-linux-image.description
  }
}

output "instance_public_ip" {
  value = aws_instance.myapp-instance.public_ip
}
