GitHub Repository Factory (Terraform)

One command to create polished GitHub repositories under my personal account.
Each repo is created, initialized, configured for GitHub Pages, and published with a templated landing page. This lets me spin up consistent, recruiter-ready projects fast.
<p align="left"> <img src="./page-live.png" alt="Project hero screenshot" width="640"> </p>

At a glance

What it does: Creates and bootstraps GitHub repos under Tristanjones7 with Pages enabled and a ready-made index.md.

Why it matters: Consistent, documented repos make it easier for teams and recruiters to review work quickly.

Tech used: Terraform, GitHub Provider v6, GitHub Pages, optional deploy keys.

Scale: Works for one repo or many (for_each) without legacy provider pitfalls.

Contents:

Highlights
How it works
Architecture
Setup
Usage
Screenshots
Inputs & Outputs
Security Notes
Troubleshooting
Roadmap
Contact


Personal owner: Targets Tristanjones7 so repos live on my profile.

GitHub Pages: Automatically enabled on the repository.

Templated landing page: index.md is generated from templates/index.tftpl with my name, avatar, and date.

Propagation-safe UX: Opens the repo via gh using the correct owner/repo and a short wait to avoid API race conditions.

Factory mode: Easily extend to create multiple repos with for_each.
Module best practice: No provider blocks inside child modules (so count/for_each/depends_on work reliably).
How it works
Create the repo via Terraform (github_repository).
Enable GitHub Pages on the repo (pages block).
Render a Markdown file from the template (templatefile) and commit it to main (github_repository_file).
Open the repo in the browser using the GitHub CLI with a graceful fallback if GraphQL lags.
Result: a clean repo with a live project page, ready to share.
Architecture
<p align="left"> <img src="./images/architecture.png" alt="Architecture diagram" width="640"> </p>
Key resources
github_repository — creates and configures the repo (visibility, Pages).
github_repository_file — commits index.md generated from index.tftpl.
data.github_user — pulls my avatar URL (sized via &s=200).
time_static — fixes a stable year for the footer (no drift on plan).
Setup
Prerequisites
Terraform 1.5+
Personal Access Token with repo scope
export TF_VAR_github_token=<your_token>
(Optional) GitHub CLI (gh) logged in locally
Clone & structure
/
├─ main.tf
└─ templates/
   └─ index.tftpl
Key configuration (personal owner)
provider "github" {
  token = var.github_token
  owner = "Tristanjones7"
}
Usage
Create a single repo (Pages + templated landing page)
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
echo "✅ Repository created: https://github.com/${self.full_name}"
EOT
  }
}

data "github_user" "owner" { username = "Tristanjones7" }
resource "time_static" "now" {}

locals {
  year = formatdate("YYYY", time_static.now.rfc3339)
}

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
Template: templates/index.tftpl
<p align="center">
  <img src="${avatar}" alt="${name} avatar" width="128" height="128" style="border-radius:50%;"/>
</p>

<h1 align="center">${name}</h1>
<p align="center"><em>Project Info Page</em></p>
<p align="center"><sub>Last updated: ${date}</sub></p>

<hr/>

## 🚀 Projects

| Project Name        | Web Page                                                          | Link                                                                 |
|---------------------|-------------------------------------------------------------------|----------------------------------------------------------------------|
| mtc-backend-prod    | No Page                                                           | [GitHub](https://github.com/morethancertified/mtc-backend-prod)      |
| mtc-infra-prod      | [Webpage](https://morethancertified.github.io/mtc-infra-prod/)    | [GitHub](https://github.com/morethancertified/mtc-infra-prod)        |
| mtc-frontend-prod   | [Webpage](https://morethancertified.github.io/mtc-frontend-prod/) | [GitHub](https://github.com/morethancertified/mtc-frontend-prod)     |

---

<p align="center">
  <sub>© ${date} ${name}</sub>
</p>
Run
terraform init
terraform validate
terraform apply
Update only the page content
terraform plan  -target=github_repository_file.index
terraform apply -target=github_repository_file.index
Screenshots
Place images in /images and reference them in this README:
./images/hero.png — top of the project page
./images/architecture.png — architecture diagram (Terraform → GitHub → Pages)
./images/plan.png — terraform plan showing resources
./images/apply.png — terraform apply successful
./images/repo-settings.png — GitHub Pages settings enabled
./images/page-live.png — live Pages site
Tip: on macOS use ⌘ + ⇧ + 4 for area screenshots and ⌘ + ⇧ + 5 for options/recording.
Inputs & Outputs
Inputs
github_token (string, sensitive): Personal Access Token with repo scope.
Derived
owner is set to Tristanjones7 in the provider block.
avatar is pulled from data.github_user.owner.avatar_url and sized with &s=200.
date is the current year derived from time_static.
Outputs
This minimal version commits index.md. (You can easily add outputs for repo URL or full name if needed.)
Security Notes
Do not commit your token. Pass it via environment (TF_VAR_github_token).
Deploy keys (if you add them) should be generated and stored securely; treat private keys as secrets.
This project creates public repos by default—switch to visibility = "private" if required.
Troubleshooting
“Could not resolve to a Repository…”
GitHub’s GraphQL can lag a few seconds. The provisioner uses a short wait and prints the direct URL as a fallback. The repo is created; just open the link.
Owner mismatch
Ensure your provider "github" has owner = "Tristanjones7" and the token is from your personal account.
Module for_each errors
Don’t include provider blocks inside child modules. Pass providers from root with providers = { github = github }.
Roadmap
Optional: repo labels, topics, branch protection
Optional: deploy keys submodule (ED25519) for CI/CD
Optional: dynamic projects table with inputs
Optional: CODEOWNERS, PR templates, security policy
Optional: portfolio hub linking all live Pages sites
Contact
GitHub: @Tristanjones7
LinkedIn: /in/tristanjones7
Notes for reviewers (hiring managers)
This repository demonstrates:
Practical Infrastructure-as-Code with Terraform
Integration with GitHub’s API and Pages publishing
Clean automation patterns that scale across multiple repos
Attention to documentation and developer experience

One command to create polished GitHub repositories under my personal account.
Each repo is created, initialized, configured for GitHub Pages, and published with a templated landing page. This lets me spin up consistent, recruiter-ready projects fast.
<p align="left"> <img src="./images/hero.png" alt="Project hero screenshot" width="640"> </p>
At a glance
What it does: Creates and bootstraps GitHub repos under Tristanjones7 with Pages enabled and a ready-made index.md.
Why it matters: Consistent, documented repos make it easier for teams and recruiters to review work quickly.
Tech used: Terraform, GitHub Provider v6, GitHub Pages, optional deploy keys.
Scale: Works for one repo or many (for_each) without legacy provider pitfalls.
Contents
Highlights
How it works
Architecture
Setup
Usage
Screenshots
Inputs & Outputs
Security Notes
Troubleshooting
Roadmap
Contact
Highlights
Personal owner: Targets Tristanjones7 so repos live on my profile.
GitHub Pages: Automatically enabled on the repository.
Templated landing page: index.md is generated from templates/index.tftpl with my name, avatar, and date.
Propagation-safe UX: Opens the repo via gh using the correct owner/repo and a short wait to avoid API race conditions.
Factory mode: Easily extend to create multiple repos with for_each.
Module best practice: No provider blocks inside child modules (so count/for_each/depends_on work reliably).
How it works
Create the repo via Terraform (github_repository).
Enable GitHub Pages on the repo (pages block).
Render a Markdown file from the template (templatefile) and commit it to main (github_repository_file).
Open the repo in the browser using the GitHub CLI with a graceful fallback if GraphQL lags.
Result: a clean repo with a live project page, ready to share.
Architecture
<p align="left"> <img src="./images/architecture.png" alt="Architecture diagram" width="640"> </p>
Key resources
github_repository — creates and configures the repo (visibility, Pages).
github_repository_file — commits index.md generated from index.tftpl.
data.github_user — pulls my avatar URL (sized via &s=200).
time_static — fixes a stable year for the footer (no drift on plan).
Setup
Prerequisites
Terraform 1.5+
Personal Access Token with repo scope
export TF_VAR_github_token=<your_token>
(Optional) GitHub CLI (gh) logged in locally
Clone & structure
/
├─ main.tf
└─ templates/
   └─ index.tftpl
Key configuration (personal owner)
provider "github" {
  token = var.github_token
  owner = "Tristanjones7"
}
Usage
Create a single repo (Pages + templated landing page)
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
echo "✅ Repository created: https://github.com/${self.full_name}"
EOT
  }
}

data "github_user" "owner" { username = "Tristanjones7" }
resource "time_static" "now" {}

locals {
  year = formatdate("YYYY", time_static.now.rfc3339)
}

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
Template: templates/index.tftpl
<p align="center">
  <img src="${avatar}" alt="${name} avatar" width="128" height="128" style="border-radius:50%;"/>
</p>

<h1 align="center">${name}</h1>
<p align="center"><em>Project Info Page</em></p>
<p align="center"><sub>Last updated: ${date}</sub></p>

<hr/>

## 🚀 Projects

| Project Name        | Web Page                                                          | Link                                                                 |
|---------------------|-------------------------------------------------------------------|----------------------------------------------------------------------|
| mtc-backend-prod    | No Page                                                           | [GitHub](https://github.com/morethancertified/mtc-backend-prod)      |
| mtc-infra-prod      | [Webpage](https://morethancertified.github.io/mtc-infra-prod/)    | [GitHub](https://github.com/morethancertified/mtc-infra-prod)        |
| mtc-frontend-prod   | [Webpage](https://morethancertified.github.io/mtc-frontend-prod/) | [GitHub](https://github.com/morethancertified/mtc-frontend-prod)     |

---

<p align="center">
  <sub>© ${date} ${name}</sub>
</p>

Run
terraform init
terraform validate
terraform apply
Update only the page content
terraform plan  -target=github_repository_file.index
terraform apply -target=github_repository_file.index

Inputs & Outputs
Inputs
github_token (string, sensitive): Personal Access Token with repo scope.
Derived
owner is set to Tristanjones7 in the provider block.
avatar is pulled from data.github_user.owner.avatar_url and sized with &s=200.
date is the current year derived from time_static.
Outputs
This minimal version commits index.md. (You can easily add outputs for repo URL or full name if needed.)
Security Notes
Do not commit your token. Pass it via environment (TF_VAR_github_token).
Deploy keys (if you add them) should be generated and stored securely; treat private keys as secrets.
This project creates public repos by default—switch to visibility = "private" if required.
Troubleshooting
“Could not resolve to a Repository…”
GitHub’s GraphQL can lag a few seconds. The provisioner uses a short wait and prints the direct URL as a fallback. The repo is created; just open the link.
Owner mismatch
Ensure your provider "github" has owner = "Tristanjones7" and the token is from your personal account.
Module for_each errors
Don’t include provider blocks inside child modules. Pass providers from root with providers = { github = github }.

Roadmap
Optional: repo labels, topics, branch protection
Optional: deploy keys submodule (ED25519) for CI/CD
Optional: dynamic projects table with inputs
Optional: CODEOWNERS, PR templates, security policy
Optional: portfolio hub linking all live Pages sites

Contact
GitHub: @Tristanjones7
LinkedIn: /in/tristanjones7

Notes for reviewers (hiring managers)
This repository demonstrates:
Practical Infrastructure-as-Code with Terraform
Integration with GitHub’s API and Pages publishing
Clean automation patterns that scale across multiple repos
Attention to documentation and developer experience
