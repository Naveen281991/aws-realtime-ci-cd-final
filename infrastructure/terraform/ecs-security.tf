resource "aws_security_group" "alb" {
  name        = "aws-cicd-alb-sg"
  description = "Security group for the AWS CI/CD Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-cicd-alb-sg"
    Role = "load-balancer"
  }
}

resource "aws_security_group" "ecs" {
  name        = "aws-cicd-ecs-sg"
  description = "Security group for AWS CI/CD ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-cicd-ecs-sg"
    Role = "ecs-task"
  }
}