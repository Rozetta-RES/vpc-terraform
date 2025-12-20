terraform {
  backend "s3" {
    key            = "vpc/onyaku-bastion/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"         # DynamoDBテーブル名（ロック用）
  }
}
