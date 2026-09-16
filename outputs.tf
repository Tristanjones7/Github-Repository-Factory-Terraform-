output "repository_full_name" {
  description = "Full name of the repository created by the factory."
  value       = github_repository.this.full_name
}

output "repository_url" {
  description = "HTTPS URL of the generated repository."
  value       = github_repository.this.html_url
}

output "pages_url" {
  description = "Expected GitHub Pages URL for the generated repository."
  value       = "https://${var.github_owner}.github.io/${github_repository.this.name}/"
}
