variable "github_token" {
  description = "GitHub personal access token used by the provider."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub username or organization that owns the repositories."
  type        = string
  default     = "Tristanjones7"
}

variable "repository_name" {
  description = "Name of the repository to create."
  type        = string
  default     = "terraform-created-repository"
}

variable "repository_description" {
  description = "Description applied to the generated repository."
  type        = string
  default     = "Repository created and bootstrapped with Terraform"
}

variable "repository_visibility" {
  description = "Repository visibility."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.repository_visibility)
    error_message = "repository_visibility must be either public or private."
  }
}
