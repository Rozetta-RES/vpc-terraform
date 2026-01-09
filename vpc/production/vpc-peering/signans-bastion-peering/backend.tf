terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # 要変更: S3バケット名
    key            = "vpc-peering/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # 要変更: DynamoDBテーブル名
    
    # オプション: バージョニング有効化を推奨
    # versioning = true
  }
}
