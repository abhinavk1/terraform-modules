output "efs_file_system_id" {
  value = aws_efs_file_system.efs_file_system.id
}

output "mount_target_dns_names" {
  value = [aws_efs_mount_target.efs_mount_targets.*.mount_target_dns_name]
}
