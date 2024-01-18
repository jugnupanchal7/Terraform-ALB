provider "aws" {
  region = var.region
}

resource "aws_vpc" "singa_vpc" {
  cidr_block = "192.168.10.0/24"
  
  tags = {
     Name = var.def_tag["Name"]
  }
}

resource "aws_subnet" "Pub-sub" {
  count = 2
  vpc_id = aws_vpc.singa_vpc.id
  map_public_ip_on_launch = true
  cidr_block = cidrsubnet(aws_vpc.singa_vpc.cidr_block,1,count.index)
  availability_zone = var.zones[count.index]

  tags = {
    Name = "pub-sub-${count.index+1}"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.singa_vpc.id

  tags = {
    Name = var.singa_igw
  }
}

resource "aws_default_route_table" "Def_rt" {
  default_route_table_id = aws_vpc.singa_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}
resource "aws_security_group" "Multi-ports" {
  vpc_id = aws_vpc.singa_vpc.id
  name = "Multi-ports"
  dynamic "ingress" {
    for_each = [22,80,443]
        iterator = port
    content {
      description = "Allow multi-ports for vpc"      
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress  {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  tags = {
    Name = "Multi-ports"
  }
}

resource "aws_instance" "singa-insta" {
  count = 1
  ami = "ami-0172cbe2088c3bb63"
  instance_type = "t2.micro"
  key_name = "singa_key"
  vpc_security_group_ids = [aws_security_group.Multi-ports.id]
  subnet_id = aws_subnet.Pub-sub[count.index].id

  tags = {
    Name = "singa-insta"
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/jugnu/Downloads/new_singa.pem")
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum install httpd -y",
               "sudo systemctl start httpd",
               "sudo systemctl enable httpd"
             ]
  }

  provisioner "file" {
    source = "./index.html"
    destination = "/var/www/html/index.html"
  }
}
/*
resource "aws_security_group_rule" "inbound" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Sg-ALB.id
}

resource "aws_security_group_rule" "outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Sg-ALB.id
}

resource "aws_lb_target_group" "def_tg" {
   name = "tf-default-lb-tg"
   port = 80
   protocol = "HTTP"
   vpc_id = aws_vpc.singa_vpc.id

   tags = {
     Name = "Default_tg"
   }
}


resource "aws_lb" "main_ALB" {   
  name = "test-ALB"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.Sg-ALB.id]
  subnets = [for subnet in aws_subnet.Pub-sub : subnet.id]

  tags = {
    Environment = "Production"
  }
}

resource "aws_lb_listener" "FE-Listner" {
  load_balancer_arn = aws_lb.main_ALB.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.def_tg.arn
  }
}

output "lb-dns" {
  value = aws_lb.main_ALB.dns_name
}
*/