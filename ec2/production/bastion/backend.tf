# ============================================
# Terraform Backend Configuration (EC2 Project)
# ============================================
# EC2プロジェクト用のバックエンド設定
# VPCプロジェクトとは異なる key を使用

terraform {
  backend "s3" {
    # S3 バケット名（VPCプロジェクトと同じバケットを使用）
    bucket = "terraform-state-475975307153"  # 適切なバケット名に変更してください
    
    # State ファイルのパス（VPCとは異なるkeyを使用）
    key = "ec2/onyaku-basion/terraform.tfstate"
    
    # リージョン
    region = "ap-northeast-1"
    
    # 暗号化を有効化
    encrypt = true
    
    # State Lock 用の DynamoDB テーブル（VPCと共通）
    dynamodb_table = "terraform-state-lock"
  }
}
