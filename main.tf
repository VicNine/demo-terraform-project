#############  define providers and profile  #############
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

#############  define variables  #############
variable "aws_region" {
  type        = string
  description = "aws_region"
}

variable "aws_profile" {
  type        = string
  description = "aws_profile"
}

variable "vpc_cidr_block" {
  type        = string
  description = "vpc_cidr_block"
}

variable "subnet_cidr_block" {
  type        = string
  description = "subnet_cidr_block"
}

variable "env_prefix" {
  type        = string
  description = "env_prefix"
}

variable "avail_zone" {
  type        = string
  description = "subnet avail_zone"
}

variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}
variable "private_key_location" {}

#############  define resources  #############
// --> always avoid to use default resources/components
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  cidr_block        = var.subnet_cidr_block
  vpc_id            = aws_vpc.myapp-vpc.id
  availability_zone = var.avail_zone
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}

// route table == router, route traffic from internet gateway to subnet
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    "Name" = "${var.env_prefix}-rtb"
  }
}

// in order to access and be accessable from internet
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    "Name" = "${var.env_prefix}-igw"
  }
}

// by default the new created subnet will associated with the main(default) route_table within the vpc
// so here we need to associate the subnet with the route table we create before which connected to the igw
resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id      = aws_subnet.myapp-subnet-1.id
}
// sg for instance, ACL for subnet
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  // in coming traffic
  // allow ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip // ip whitelist, use cidr in order to configure a range of ip address

  }
  // allow http
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // allow traffic from anywhere
  }
  // allow all out coming traffic
  egress {
    from_port       = 0 // allow all port to out coming traffic
    to_port         = 0
    protocol        = "-1" // allow using any protocol
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    "Name" = "${var.env_prefix}-sg"
  }
}


#############  测试默认sg的改动与还原  #############
// 一旦配置过一遍默认的sg之后，删除整个block不会对在默认sg的配置发生任何改变
// 如果保留resource并且删除除了vpcid之外的所有配置将会把默认sg设置成没有任何in/out bound rules的空的sg
// 删除vpc会一并删掉默认的sg，再次创建，并且删掉对于默认sg的配置即可保留默认sg不做任何改动
// 默认sg的rule是允许所有inbound 和 outbound，并且是假的，没用的

# resource "aws_default_security_group" "myapp-default-sg" {
#   vpc_id = aws_vpc.myapp-vpc.id

#   // in coming traffic
#   // allow ssh
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = var.my_ip // ip whitelist, use cidr in order to configure a range of ip address

#   }
#   // allow http
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] // allow traffic from anywhere
#   }
#   // allow all out coming traffic
#   egress {
#     from_port       = 0 // allow all port to out coming traffic
#     to_port         = 0
#     protocol        = "-1" // allow using any protocol
#     cidr_blocks     = ["0.0.0.0/0"]
#     prefix_list_ids = []
#   }
#   tags = {
#     "Name" = "${var.env_prefix}-default-sg"
#   }
# }

// query ami
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"] // list --> can have multipal owners
  // 理论上讲filter可以有无限个
  filter {
    name   = "name"                         // key of filter
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] // list of names, also use list
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// 查看查询结构是否正确 **tf plan 就可以看
output "aws_ami_info" {
  value = "ami_id: ${data.aws_ami.latest-amazon-linux-image.id}\nami_description: ${data.aws_ami.latest-amazon-linux-image.description}"
}

// set local ssh key public key --> 只需要上传共钥就可以在aws设置key-pair，因为aws不保存私钥
// 使用 `ssh-keygen` 指令生成 key-pair
resource "aws_key_pair" "ssh-key" {
  key_name   = "${var.env_prefix}-server-key-pair"
  public_key = file(var.public_key_location) // read file from directory
}

// create ec2 instance
resource "aws_instance" "myapp-instance" {
  // Amazon Machine Image --> id of operating system images
  ami           = data.aws_ami.latest-amazon-linux-image.id // only need id
  instance_type = var.instance_type

  // if not, instance will be created in default vpc and subnet with defaultsg
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  #   // 只有首次执行创建的时候(initial run)脚本才会被执行，若之后修改例如标签，脚本就不会被执行
  #   // line 4: -a "append" -aG "append group docker with user ec2-user"
  #   // 若只有 -G 那么将会把用户从所有组移除，只保留当前指定的组
  #   user_data = <<-EOF
  #                     #!/bin/bash
  #                     sudo yum update -y && sudo yum install -y docker
  #                     sudo systemctl start docker
  #                     sudo usermod -aG docker ec2-user
  #                     docker run -p 8080:80 nginx
  #                 EOF

  ############### 使用 Provisioner代替user_data进行服务器的配置 #####################
  // provisioners are not recommended, use user_data if available
  #   user_data = file("entry-script.sh")
  // 1st step is estanblish the connection to the remote server using ssh
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  // File provisioner can upload local file to remote server
  // 可以在provisioner中单独定义connection代码块可以允许provisioner访问到不同的服务器
  provisioner "file" {
    source      = "entry-script.sh" // local文件路径
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  // remote-exec provisioner can exct commands/scripts on remote server
  provisioner "remote-exec" {
    inline = [ // inline block uses list
      "export ENV=env",
      "mkdir newdir",
      "sh entry-script-on-ec2.sh" // 会有权限问题
    ]
  }

  // commands that will exct on local machine when apply/destroy
  // use --> local_file if possible
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt" // just an eg
  }

  tags = {
    "Name" = "${var.env_prefix}-server"
  }
}

// 输出public ip
output "instance_public_ip" {
  value = aws_instance.myapp-instance.public_ip
}
