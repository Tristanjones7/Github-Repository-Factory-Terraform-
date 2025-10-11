# GitHub Repository Factory (Terraform) 

A reusable Terraform setup to create polished repositories under **your personal account** . It can:
- Create one or many repositories (with `for_each`)
- Enable **GitHub Pages** and publish a templated `index.md` from `index.tftpl`
- Optionally add **deploy keys** for CI/CD
- Optionally bootstrap **labels**, **branch protection**, **secrets/variables**, and **topics**
- Handle GitHub API timing gracefully when opening repos with the `gh` CLI

---

## Why this exists

When you’re building a portfolio or spinning up many project repos, you shouldn’t be hand-clicking through settings. This factory standardizes everything so each repo ships **consistent, documented, and recruiter-friendly**.

---

## Features

- **Personal owner**: targets `user` by default  
- **Repo provisioning**: public/private, auto-init, default branch, topics
- **Pages**: enables GitHub Pages and publishes `index.md` generated from `templates/index.tftpl`
- **Templating**: injects variables like avatar, name, and year
- **Deploy keys (optional)**: per-repo ED25519 keypair for automation
- **Quality of life**: `gh` open with `${self.full_name}` + short delay to avoid GraphQL race (i done this as i changed my account from personal to org mid deployment)
- **Scale**: create multiple repos with `for_each` without legacy provider blocks in modules

---

## Prerequisites

- Terraform ≥ 6.0  
- GitHub Personal Access Token with `repo` scope  
- (Optional) GitHub CLI (`gh`) authenticated locally for the “open in browser” step
- unset GITHUB_TOKEN && gh auth login -h github.com -p https -s delete_repo -w  - ran this script everytime i opened codespaces

Export your token:
```bash
export TF_VAR_github_token=<your_personal_access_token>
Quick Start (single repo)
Files:
main.tf – your Terraform configuration
templates/index.tftpl – Markdown template for the landing page
Minimal working example (personal owner + Pages + templated index):
terraform {
  required_providers {
    github = { source = "integrations/github", version = "~> 6.0" }
    time   = { source = "hashicorp/time",       version = "~> 0.11" }
  }
}

variable "github_token" { type = string, sensitive = true }

provider "github" {
  token = var.github_token
  owner = "Tristanjones7"
}

resource "github_repository" "this" {
  name        = "my_info_page"
  description = "Repository information for project"
  visibility  = "public"
  auto_init   = true

  pages { source { branch = "main" path = "/" } }

  provisioner "local-exec" {
    command = <<EOT
sleep 8
gh repo view ${self.full_name} --web 2>/dev/null || \
echo " Repository created: https://github.com/${self.full_name}"
EOT
  }
}

data "github_user" "owner" { username = "" }
resource "time_static" "now" {}
locals { year = formatdate("YYYY", time_static.now.rfc3339) }

resource "github_repository_file" "index" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = "index.md"
  overwrite_on_create = true
  commit_message      = "Update index.md from Terraform template"

  content = templatefile("${path.module}/templates/index.tftpl", {
    avatar = "${data.github_user.owner.avatar_url}&s=200"
    name   = "Tristan Jones"
    date   = local.year
  })
}
templates/index.tftpl:
<p align="center">
  <img src="${avatar}" alt="${name} avatar" width="128" height="128" style="border-radius:50%;"/>
</p>

<h1 align="center">${name}</h1>
<p align="center"><em>Project Info Page</em></p>
<p align="center"><sub>Last updated: ${date}</sub></p>

<hr/>

## 🚀 Projects

| Project Name        | Web Page                                                          | Link                                                                 |
|---------------------|----------------------------------------------|----------------------------------------------------------------------|
| mtc-backend-prod    | No Page                                      | [GitHub](https://github.com//backend-prod)      |
| mtc-infra-prod      | [Webpage](https://.github.io/infra-prod/)    | [GitHub](https://github.com//infra-prod)        |
| mtc-frontend-prod   | [Webpage](https://.github.io/frontend-prod/) | [GitHub](https://github.com//frontend-prod)     |

---

<p align="center">
  <sub>© ${date} ${name}</sub>
</p>
Run:
terraform init
terraform validate
terraform apply
Update just the page:
terraform plan  -target=github_repository_file.index
terraform apply -target=github_repository_file.index
Create many repos (factory mode)
locals {
  repo_names = toset([
    "proj-a",
    "proj-b",
    "proj-c",
  ])
}

resource "github_repository" "repos" {
  for_each   = local.repo_names
  name       = each.value
  visibility = "public"
  auto_init  = true
  pages { source { branch = "main" path = "/" } }
}

data "github_user" "owner" { username = "Tristanjones7" }
resource "time_static" "now" {}
locals { year = formatdate("YYYY", time_static.now.rfc3339) }

resource "github_repository_file" "indexes" {
  for_each            = local.repo_names
  repository          = github_repository.repos[each.key].name
  branch              = "main"
  file                = "index.md"
  overwrite_on_create = true
  commit_message      = "Update index.md from Terraform template"
  content = templatefile("${path.module}/templates/index.tftpl", {
    avatar = "${data.github_user.owner.avatar_url}&s=200"
    name   = "Tristan Jones"
    date   = local.year
  })
}
Optional components
Keep submodules provider-free and pass the root provider with providers = { github = github }.
Deploy key (read-only)
# modules/deploy-key/variables.tf
variable "repo_name" { type = string }
variable "title"     { type = string }
variable "read_only" { type = bool   default = true }
# modules/deploy-key/main.tf
resource "tls_private_key" "this" { algorithm = "ED25519" }

resource "github_repository_deploy_key" "this" {
  repository = var.repo_name
  title      = var.title
  read_only  = var.read_only
  key        = tls_private_key.this.public_key_openssh
}

output "private_key_pem" { value = tls_private_key.this.private_key_pem, sensitive = true }
# root usage
module "deploy_key" {
  source    = "./modules/deploy-key"
  providers = { github = github }
  repo_name = github_repository.this.name
  title     = "ci-readonly"
}
Labels, topics, branch protection (examples)
resource "github_repository_topics" "this" {
  repository = github_repository.this.name
  topics     = ["terraform", "iac", "portfolio", "github-pages"]
}

resource "github_issue_label" "good_first_issue" {
  repository = github_repository.this.name
  name       = "good first issue"
  color      = "a2eeef"
}

resource "github_branch_protection" "main" {
  repository_id  = github_repository.this.node_id
  pattern        = "main"
  enforce_admins = true
  required_pull_request_reviews {
    required_approving_review_count = 1
  }
}
Troubleshooting



Project structure
/
├─ main.tf
├─ modules/
│  └─ deploy-key/
│     ├─ main.tf
│     └─ variables.tf
└─ templates/
   └─ index.tftpl
