resource "aws_security_group" "db" {
  name        = "db"
  description = "For database"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 15432
    to_port     = 15432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.21.0"

  identifier = "wl-postgres"

  engine            = "postgres"
  engine_version    = "9.6.9"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
  #   storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = "notesapi"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "notesadmin"

  password = "TODO" #TODO: Placeholder only
  port     = "15432"

  vpc_security_group_ids = [aws_security_group.db.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  #   backup_retention_period = 0

  tags = local.common_tags

  #   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.subnets.ids

  # DB parameter group
  family = "postgres9.6"

  # DB option group
  major_engine_version = "9.6"

  # Snapshot name upon DB deletion
  #   final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  #   deletion_protection = false

  publicly_accessible = true

}
