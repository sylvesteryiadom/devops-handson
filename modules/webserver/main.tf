# create instance level security group
resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.my_ip}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-default-sg"
  }
}
# get the most recent aws ami image
data "aws_ami" "latest_aws_linux_image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest_aws_linux_image.id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  key_name                    = aws_key_pair.myapp_key.key_name

  user_data = file("user-data-script.sh")

  user_data_replace_on_change = true

  tags = {
    Name : "${var.env_prefix}-server"
  }
}

# generate keypair for ec2 instance
resource "tls_private_key" "myapp_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# store in AWS secret manager
resource "aws_secretsmanager_secret" "myapp_ssh" {
  name = "${var.env_prefix}-ec2-ssh-private-key"
}
# store key value in secret manager
resource "aws_secretsmanager_secret_version" "myapp_ssh_version" {
  secret_id     = aws_secretsmanager_secret.myapp_ssh.id
  secret_string = tls_private_key.myapp_ssh.private_key_pem
}
# create the keypair. This does what you will manually do on the console
resource "aws_key_pair" "myapp_key" {
  key_name   = "${var.env_prefix}-ec2-key"
  public_key = tls_private_key.myapp_ssh.public_key_openssh
}