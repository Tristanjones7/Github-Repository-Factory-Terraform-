terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

data "github_user" "owner" {
  username = var.github_owner
}

resource "time_static" "generated" {}

locals {
  year = formatdate("YYYY", time_static.generated.rfc3339)
}

resource "github_repository" "this" {
  name        = var.repository_name
  description = var.repository_description
  visibility  = var.repository_visibility
  auto_init   = true

  has_issues   = true
  has_projects = false
  has_wiki     = false

  pages {
    source {
      branch = "main"
      path   = "/"
    }
  }
}

resource "github_repository_file" "index" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = "index.md"
  overwrite_on_create = true
  commit_message      = "Bootstrap repository landing page"

  content = templatefile("${path.module}/templates/index.tftpl", {
    avatar = "${data.github_user.owner.avatar_url}&s=200"
    name   = var.github_owner
    date   = local.year
    repo   = github_repository.this.name
  })
}
