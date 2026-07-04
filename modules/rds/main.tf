resource "random_password" "master" {
  length  = 32
  special = false # avoid characters that need URL-encoding in a DATABASE_URL connection string
}

# Self-managed Secrets Manager entry (rather than RDS's manage_master_user_password
# feature) so this module fully controls the secret's name/shape — stage 2 reads
# it back by this same name to build each service's DATABASE_URL.
resource "aws_secretsmanager_secret" "master_password" {
  name                    = "${var.name}-rds-master-password"
  recovery_window_in_days = 0 # demo-scale: allow immediate deletion, not a 7-30 day hold
}

resource "aws_secretsmanager_secret_version" "master_password" {
  secret_id     = aws_secretsmanager_secret.master_password.id
  secret_string = random_password.master.result
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-postgres"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name}-postgres" }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-postgres"
  description = "Allow Postgres from the EKS node security group only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-postgres" }
}

# pgvector (used by stagecraft-api's log_embeddings table) needs Postgres
# >= 15.2/14.7/13.10 but no shared_preload_libraries or parameter-group change —
# `CREATE EXTENSION vector` (already in stagecraft-api's alembic migration 0007)
# works directly once the engine version supports it.
resource "aws_db_instance" "this" {
  identifier     = "${var.name}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 4
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_days
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-postgres-final"

  deletion_protection = false

  tags = { Name = "${var.name}-postgres" }
}
