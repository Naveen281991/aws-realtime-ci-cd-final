# infrastructure/terraform/rds.tf

resource "aws_db_subnet_group" "postgres" {
  name       = local.rds_subnet_group
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = local.rds_subnet_group
  }
}

resource "aws_security_group" "postgres" {
  name        = "aws-enterprise-cicd-postgres-${local.resource_suffix}"
  description = "Allow PostgreSQL only from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-enterprise-cicd-postgres-${local.resource_suffix}"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = local.rds_identifier

  engine         = "postgres"
  engine_version = "17"

  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "app"
  username = "app"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection = true
  skip_final_snapshot = false
  apply_immediately   = false

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = local.rds_identifier
  }

  depends_on = [
    aws_db_subnet_group.postgres,
    aws_security_group.postgres,
  ]
}