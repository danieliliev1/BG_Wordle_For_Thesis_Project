# Data source, който автоматично следи SHA хаша на имиджа в ECR
data "aws_ecr_image" "lambda_image" {
  repository_name = "bg-wordle-lambda-project"
  image_tag       = "latest"
}

# IAM роля за Lambda функцията
resource "aws_iam_role" "lambda_exec_role" {
    name = "bg-wordle-lambda-exec-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

# Свързване на ролята с минималните базови права (CloudWatch логване)
resource "aws_iam_role_policy_attachment" "lambda_admin" {
    role       = aws_iam_role.lambda_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda функция, която ще работи с Docker контейнер
resource "aws_lambda_function" "wordle_lambda" {
    function_name = "bg-wordle-backend" 
    role          = aws_iam_role.lambda_exec_role.arn
    package_type  = "Image"
    
    # Връзва се уникалния ID (SHA), който идва от data ресурса
    image_uri     = "090565619636.dkr.ecr.eu-central-1.amazonaws.com/bg-wordle-lambda-project@${data.aws_ecr_image.lambda_image.id}"

    timeout     = 15
    memory_size = 256

    # Слага се порта 8080 като променлива на средата
    environment {
        variables = {
            PORT = "8080"
        }
    }

    depends_on = [
        aws_iam_role_policy_attachment.lambda_admin
    ]
} 

# Публичен HTTPS URL адрес за достъп на функцията
resource "aws_lambda_function_url" "lambda_public_url" {
    function_name      = aws_lambda_function.wordle_lambda.function_name
    authorization_type = "NONE"

    cors {
        allow_credentials = false
        allow_origins     = ["*"]
        allow_methods     = ["*"]
        allow_headers     = ["date", "keep-alive", "user-agent", "x-amzn-lambda-proxy-auth", "x-amzn-trace-id"]
        max_age           = 86400
    }

    # URL адреса първо трябва да изчака да се създаде правото за достъп
    depends_on = [aws_lambda_permission.allow_public_access]
}

# Output 
output "lambda_public_url" {
    value       = aws_lambda_function_url.lambda_public_url.function_url
    description = "Публичният уеб адрес на твоето Wordle приложение."
}

# Разрешение (Permission) за публичен достъп до Lambda URL адреса
resource "aws_lambda_permission" "allow_public_access" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.wordle_lambda.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}