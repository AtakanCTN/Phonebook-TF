resource "aws_security_group" "alb-sg-web" {
  name        = "allow_tl1as"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.existing_vpc.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-ph"
  }
}

resource "aws_security_group" "phonbook-sg-web" {
  name        = "allow_tfasdls"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.alb-sg-web.id]
  }
    ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-ph"
  }
}

resource "aws_security_group" "db-sg-web" {
  name        = "allow_tdasdls"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.phonbook-sg-web.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-ph"
  }
}