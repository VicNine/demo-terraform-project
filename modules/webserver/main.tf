
// sg for instance, ACL for subnet
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = var.vpc_id

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

// query ami
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"] // list --> can have multipal owners
  // 理论上讲filter可以有无限个
  filter {
    name   = "name"       // key of filter
    values = var.ami_name // list of names, also use list
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
  subnet_id              = var.subnet_id
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

  user_data = file("entry-script.sh")

  tags = {
    "Name" = "${var.env_prefix}-server"
  }
}
