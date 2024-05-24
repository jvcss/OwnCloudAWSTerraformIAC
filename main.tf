terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "sa-east-1"
}

# Selecionar a imagem AMAZON LINUX
data "aws_ami" "amzn_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Criação da VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# Criação da Sub-rede
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Isso garante que as instâncias na sub-rede obtenham IPs públicos automaticamente

  tags = {
    Name = "main_subnet"
  }
}

# Definir regras de acesso
resource "aws_security_group" "allow_ssh_http_https" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Para segurança, considere restringir ao seu IP
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instalação da chave RSA para SSH
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer_key"
  public_key = file("C:/Users/vitim/.ssh/novarsa.pub")
}

# Criação da instância EC2
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amzn_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_key.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_https.id]
  associate_public_ip_address = true  # Isso garante que a instância tenha um IP público

  tags = {
    Name = "AppServerInstance5"
  }
}

# Automatiza Continuos Deploy com Docker Compose
resource "null_resource" "install_dependencies" {
  provisioner "remote-exec" {
    inline = [
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo chkconfig docker on",
      "sudo usermod -aG docker ec2-user",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo yum install -y git",
      "git clone https://github.com/jvcss/OwnCloudAWSTerraformIAC.git ~/cliente",
      "cd ~/cliente",
      "sed -i 's/localhost/${aws_instance.app_server.private_ip}/g' ~/cliente/nginx/nginx.conf",
      "sed -i 's/localhost/${aws_instance.app_server.private_ip}/g' ~/cliente/docker-compose.yml"
    ]
    connection {
      # usamos endereço publico DNS
      host = aws_instance.app_server.public_dns
      # usuario da instancia
      user = "ec2-user"
      # caminho da chave SSH privada
      private_key = file("C:/Users/vitim/.ssh/novarsa.pem")
    }
  }
  depends_on = [aws_instance.app_server]
}

# Reinicialização da instância porque é necessario após garantir as permissões de acesso do docker
resource "null_resource" "reboot_instance" {
  provisioner "remote-exec" {
    inline = [
      "sudo reboot"
    ]
    connection {
      host = aws_instance.app_server.public_dns
      user = "ec2-user"
      private_key = file("C:/Users/vitim/.ssh/novarsa.pem")  # 
    }
  }
  depends_on = [null_resource.install_dependencies]
}

# Comando para iniciar o Docker Compose após reiniciar instancia e clonar o repositório
# resource "null_resource" "start_docker_compose" {
#   provisioner "remote-exec" {
#     inline = [
#       "cd ~/cliente",  # Entrar no diretório clonado
#       "docker-compose up -d",  # Iniciar o Docker Compose em modo detached (sem prender o terminal aos logs)
#     ]
#     connection {
#       host = aws_instance.app_server.public_dns
#       user = "ec2-user"
#       private_key = file("C:/Users/vitim/.ssh/novarsa.pem")
#     }
#   }

#   depends_on = [null_resource.reboot_instance]
# }
