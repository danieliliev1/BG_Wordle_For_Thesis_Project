resource "aws_ecr_repository" "wordle_repo" {
  name                 = "bg-wordle-lambda-project"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.wordle_repo.repository_url
  description = "URL адресът на ECR хранилището."
}