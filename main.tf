#--------------------------------------------------------------
# Lightsail keypair
#--------------------------------------------------------------
resource "aws_lightsail_key_pair" "lightsail_key" {
  name = "lightsail_key"
  public_key = file("lightsail_key.pub")
}

#--------------------------------------------------------------
# Lightsail Instance
#--------------------------------------------------------------
resource "aws_lightsail_instance" "instance" {
  count = length(var.lightsail_cidr)

  name              = element(var.instance_name, count.index)
  availability_zone = element(var.azs, count.index)
  blueprint_id      = var.wp_blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = aws_lightsail_key_pair.lightsail_key.name
  user_data	    = file("./bootstrap.sh")
}

#--------------------------------------------------------------
# RDS
#--------------------------------------------------------------

resource "aws_db_subnet_group" "db-subnet-group" {
  name        = var.db_name
  subnet_ids  = aws_subnet.db-subnet.*.id
}

resource "aws_db_instance" "db" {
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = var.engine
  engine_version         = var.engine_version
  multi_az		 = true
  instance_class         = var.db_instance
  identifier             = var.db_name
  username               = var.db_username
  password               = data.aws_secretsmanager_secret_version.db-password.secret_string
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]

  depends_on = [
	aws_secretsmanager_secret_version.db-password
  ] 

}

#--------------------------------------------------------------
# Security group
#--------------------------------------------------------------

resource "aws_security_group" "alb-sg" {
  name        = "vpc_alb_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "lightsail-sg" {
  name = "lightsail-sg"

  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = { for i in var.ingress_config : i.port => i }

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups  = [aws_security_group.alb-sg.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Allows wordpress to access the RDS instances"
  vpc_id      = aws_vpc.vpc.id
ingress {
    description      = "lightsail to MYSQL"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.lightsail-sg.id]
  }
egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

#--------------------------------------------------------------
# ALB
#--------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "lightsail-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = aws_subnet.public-subnet.*.id
  ip_address_type    = "ipv4"

  depends_on = [ aws_security_group.alb-sg ]

}
resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  target_type = "ip"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0568200b8564da3bc"

  lifecycle {
	create_before_destroy = true
  }

  }

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
}


resource "aws_lb_target_group_attachment" "this" {
  count = length(var.lightsail_cidr)

  target_group_arn = aws_lb_target_group.alb-target-group.arn
  target_id        = element(aws_lightsail_instance.instance.*.private_ip_address, count.index)
  port             = 80
}
