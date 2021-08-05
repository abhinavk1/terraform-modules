output "repository_url" {
  value = google_container_registry.registry.bucket_self_link
}
