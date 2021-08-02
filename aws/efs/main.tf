resource "aws_efs_file_system" "efs_file_system" {
  performance_mode = var.performance_mode

  tags = {
    Name = var.name
  }
}

resource "aws_efs_mount_target" "efs_mount_targets" {
  count           = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}
