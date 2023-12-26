// select vpc and sunbets
variable "existing_vpc_id" {
  default = "vpc-0af49282be2af925a"
}

data "aws_vpc" "existing_vpc" {
  id = var.existing_vpc_id
}

data "aws_subnets" "existing_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["clarus-az1a*"]
  }
}

// create template 
resource "aws_launch_template" "phonebook-lt" {
  name = "phonebook"
  image_id = data.aws_ami.web-ami.id
  instance_type = "t2.micro"
  key_name = var.key-name
  vpc_security_group_ids = [aws_security_group.phonbook-sg-web.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "phonebook-website"
    }
  }
  user_data = base64encode(templatefile("user-data.sh", {git-token = var.git-token, git-name = var.git-name} ))
}

// create load balancer target group
resource "aws_lb_target_group" "phonebook-lb-tg" {
  name        = "ph-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing_vpc.id

  health_check {
    
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

// create load balancer
resource "aws_lb" "phonebook-lb" {
  name               = "ph-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb-sg-web.id]
  subnets            = data.aws_subnets.existing_vpc_subnets.ids
}


// create load balancer listener
resource "aws_lb_listener" "phonebook-lb-listener" {
  load_balancer_arn = aws_lb.phonebook-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.phonebook-lb-tg.arn
  }
}

// create autoscaling group

resource "aws_autoscaling_group" "bar" {
  name                      = "ph-autoscaling"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  target_group_arns = [aws_lb_target_group.phonebook-lb-tg.arn]
  vpc_zone_identifier = aws_lb.phonebook-lb.subnets
  
  launch_template {
    id      = aws_launch_template.phonebook-lt.id
    version = aws_launch_template.phonebook-lt.latest_version
  }
}


// create DB

 resource "aws_db_subnet_group" "existing_vpc_subnets" {
   name        = "existing-vpc-subnets"
   description = "DB subnet group for existing VPC"
   subnet_ids  = data.aws_subnets.existing_vpc_subnets.ids
 }

resource "aws_db_instance" "phonebook-db" {
  vpc_security_group_ids      = [aws_security_group.db-sg-web.id]
  db_subnet_group_name        = aws_db_subnet_group.existing_vpc_subnets.name
  instance_class              = "db.t2.micro"
  allocated_storage           = 20
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = 0
  identifier                  = "phonebook-app-db"
  db_name                     = "phonebook"
  engine                      = "mysql"
  engine_version              = "8.0.28"
  username                    = "admin"
  password                    = "Oliver_1"
  monitoring_interval         = 0
  multi_az                    = false
  port                        = 3306
  publicly_accessible         = false
  skip_final_snapshot         = true
}

// create git 
resource "github_repository_file" "dbendpoint" {
  content             = aws_db_instance.phonebook-db.address
  file                = "dbserver.endpoint"
  repository          = "phonebook"
  overwrite_on_create = true
  branch              = "main"
}

// route53

data "aws_route53_zone" "selected" {
  name = var.hosted-zone
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_lb.phonebook-lb.dns_name
    zone_id                = aws_lb.phonebook-lb.zone_id
    evaluate_target_health = true
  }
}