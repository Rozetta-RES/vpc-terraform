# VPC Peering Terraform Configuration

踏み台VPCとアプリケーションVPCをVPC Peeringで接続し、踏み台経由でRDSにアクセスできるようにするTerraform構成です。

## 構成概要

```
踏み台VPC (10.0.0.0/16)
  ├─ 踏み台インスタンス
  └─ VPC Peering ←→ アプリVPC (10.1.0.0/16)
                        └─ RDS (MySQL/Aurora)
```

## 前提条件

- 既存の踏み台VPCとアプリVPCがある
- RDSがアプリVPC内に存在する
- Terraform 1.5以上がインストール済み
- AWS CLIで適切な認証情報が設定済み

## セットアップ手順

### 1. S3バケットとDynamoDBテーブルの作成

Terraform stateを管理するためのリソースを事前に作成してください:

```bash
# S3バケット作成
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

# バージョニング有効化
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# 暗号化有効化
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# DynamoDBテーブル作成
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1
```

### 2. backend.tfの編集

`backend.tf`のS3バケット名とDynamoDBテーブル名を実際の値に変更してください:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # ← 変更
    key            = "vpc-peering/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # ← 変更
  }
}
```

### 3. terraform.tfvarsの作成

サンプルファイルをコピーして編集します:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`を編集し、実際の値を設定:

```hcl
bastion_vpc_id   = "vpc-0123456789abcdef0"  # 踏み台VPC ID
app_vpc_id       = "vpc-0fedcba9876543210"  # アプリVPC ID
bastion_vpc_cidr = "10.0.0.0/16"
app_vpc_cidr     = "10.1.0.0/16"

bastion_route_table_ids = [
  "rtb-0123456789abcdef0",
]

app_route_table_ids = [
  "rtb-0aaaaaaaaaaaaaaa",
  "rtb-0bbbbbbbbbbbbbb",
  "rtb-0cccccccccccccc",
]

rds_security_group_id = "sg-0123456789abcdef0"
rds_port              = 3306
```

### 4. 必要な情報の取得方法

#### VPC IDとCIDRの確認
```bash
# VPC一覧表示
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
```

#### ルートテーブルIDの確認
```bash
# 踏み台VPCのルートテーブル
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-0123456789abcdef0" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# アプリVPCのルートテーブル
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-0fedcba9876543210" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

#### RDSセキュリティグループIDの確認
```bash
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,VpcSecurityGroups[0].VpcSecurityGroupId]' \
  --output table
```

### 5. Terraformの実行

```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# 適用
terraform apply
```

## 接続方法

### SSHポートフォワーディングでRDSに接続

```bash
# 踏み台インスタンスにSSH接続し、ポートフォワーディング
ssh -i ~/.ssh/your-key.pem \
  -L 3306:your-rds-endpoint.ap-northeast-1.rds.amazonaws.com:3306 \
  ec2-user@bastion-public-ip

# 別のターミナルからローカル接続
mysql -h 127.0.0.1 -P 3306 -u dbuser -p
```

### Session Manager経由で接続 (推奨)

Session Managerを使用する場合、踏み台インスタンスへのSSHポート開放が不要です:

```bash
# Session Manager経由でポートフォワーディング
aws ssm start-session \
  --target i-0123456789abcdef0 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["your-rds-endpoint.ap-northeast-1.rds.amazonaws.com"],"portNumber":["3306"],"localPortNumber":["3306"]}'

# 別のターミナルからローカル接続
mysql -h 127.0.0.1 -P 3306 -u dbuser -p
```

## セキュリティ考慮事項

1. **最小権限の原則**: RDSへのアクセスは踏み台VPCからのみ許可
2. **SSH接続制限**: `allowed_ssh_cidr_blocks`で自分のIPのみに制限
3. **Session Manager推奨**: SSH公開を避け、Session Manager経由でのアクセスを推奨
4. **ネットワークACL**: 必要に応じてネットワークACLで追加制御

## トラブルシューティング

### 接続できない場合のチェックリスト

1. VPC Peering接続が`active`状態か確認
   ```bash
   aws ec2 describe-vpc-peering-connections \
     --filters "Name=status-code,Values=active"
   ```

2. ルートテーブルにPeeringルートが追加されているか確認
   ```bash
   aws ec2 describe-route-tables --route-table-ids rtb-xxxxx
   ```

3. セキュリティグループで踏み台VPCからのアクセスが許可されているか確認
   ```bash
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   ```

4. RDSエンドポイントが正しいか確認
   ```bash
   aws rds describe-db-instances --db-instance-identifier your-db
   ```

## リソースの削除

```bash
terraform destroy
```

## ファイル構成

```
.
├── backend.tf              # S3/DynamoDB backend設定
├── versions.tf             # Terraformとproviderバージョン
├── variables.tf            # 変数定義
├── vpc_peering.tf          # VPC Peering接続とルート
├── security_groups.tf      # セキュリティグループルール
├── outputs.tf              # 出力値
├── terraform.tfvars.example # 変数のサンプル
└── README.md               # このファイル
```

## 参考リンク

- [AWS VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
