# RDS セキュリティグループ一括更新スクリプト

既存のRDSセキュリティグループに対して、踏み台環境VPCからのアクセスを一括で許可するスクリプトです。

## ファイル構成

```
.
├── add-bastion-access-to-rds-sgs.sh    # Bashスクリプト版
├── add-bastion-access-to-rds-sgs.py    # Pythonスクリプト版
├── list-rds-security-groups.py         # RDS SG一覧取得ツール
└── README.md                            # このファイル
```

## 前提条件

### 共通
- AWS CLIまたはboto3の認証設定済み
- RDSセキュリティグループへの変更権限

### Bashスクリプト
- AWS CLI v2
- jq (JSON処理用)

```bash
# macOS
brew install jq

# Amazon Linux/RHEL/CentOS
sudo yum install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Pythonスクリプト
- Python 3.6以上
- boto3

```bash
pip install boto3
```

## 使い方

### ステップ1: 対象セキュリティグループの確認

まず、RDSに紐づいているセキュリティグループを確認します:

```bash
python3 list-rds-security-groups.py
```

出力例:
```
================================================================================
RDS インスタンスとセキュリティグループ一覧
================================================================================

1. RDS: production-mysql
   Engine: mysql
   VPC: vpc-12345678
   Security Groups:
     - sg-abc12345 (rds-mysql-sg)
       Security group for MySQL RDS
     - sg-def67890 (rds-backup-sg)
       Backup access security group

2. RDS: staging-postgres
   Engine: postgres
   VPC: vpc-87654321
   Security Groups:
     - sg-ghi11111 (rds-postgres-sg)
       Security group for PostgreSQL RDS

--------------------------------------------------------------------------------
すべてのセキュリティグループID (スクリプトにコピペ用):
--------------------------------------------------------------------------------
SECURITY_GROUPS = [
    "sg-abc12345",
    "sg-def67890",
    "sg-ghi11111",
]
```

### ステップ2: スクリプトの設定

BashまたはPythonスクリプトのどちらかを選択し、以下の値を編集します:

#### Bashスクリプト (`add-bastion-access-to-rds-sgs.sh`)

```bash
# 踏み台VPC CIDR (要変更)
BASTION_VPC_CIDR="10.0.0.0/16"

# RDSポート (MySQLの場合は3306、PostgreSQLの場合は5432)
RDS_PORT=3306

# リージョン
REGION="ap-northeast-1"

# 対象セキュリティグループ (ステップ1で取得したIDを設定)
SECURITY_GROUPS=(
    "sg-abc12345"
    "sg-def67890"
    "sg-ghi11111"
)

# ドライランモード (実行時はfalseに変更)
DRY_RUN=true
```

#### Pythonスクリプト (`add-bastion-access-to-rds-sgs.py`)

```python
# 踏み台VPC CIDR (要変更)
BASTION_VPC_CIDR = "10.0.0.0/16"

# RDSポート (MySQLの場合は3306、PostgreSQLの場合は5432)
RDS_PORT = 3306

# リージョン
REGION = "ap-northeast-1"

# 対象セキュリティグループ (ステップ1で取得したIDを設定)
SECURITY_GROUPS = [
    "sg-abc12345",
    "sg-def67890",
    "sg-ghi11111",
]

# ドライランモード (実行時はFalseに変更)
DRY_RUN = True
```

### ステップ3: ドライラン実行

まずはドライランモードで実行し、変更内容を確認します:

```bash
# Bashスクリプトの場合
chmod +x add-bastion-access-to-rds-sgs.sh
./add-bastion-access-to-rds-sgs.sh

# Pythonスクリプトの場合
python3 add-bastion-access-to-rds-sgs.py
```

出力例:
```
===================================================
RDS セキュリティグループ更新スクリプト
===================================================

設定:
  踏み台VPC CIDR: 10.0.0.0/16
  RDSポート: 3306
  リージョン: ap-northeast-1
  ドライランモード: True

対象セキュリティグループ数: 3

---------------------------------------------------
処理中: sg-abc12345
  名前: rds-mysql-sg
  VPC: vpc-12345678
  → [DRY RUN] ルールを追加します

---------------------------------------------------
処理中: sg-def67890
  名前: rds-backup-sg
  VPC: vpc-12345678
  → ルールは既に存在します (スキップ)

===================================================
処理完了
===================================================
成功: 2
スキップ (既存): 1
エラー: 0
```

### ステップ4: 本番実行

ドライランの結果を確認し、問題なければ本番実行します:

#### Bashスクリプト

```bash
# スクリプト内の DRY_RUN=false に変更
sed -i 's/DRY_RUN=true/DRY_RUN=false/' add-bastion-access-to-rds-sgs.sh

# 実行
./add-bastion-access-to-rds-sgs.sh
```

#### Pythonスクリプト

```python
# スクリプト内の DRY_RUN = False に変更
sed -i 's/DRY_RUN = True/DRY_RUN = False/' add-bastion-access-to-rds-sgs.py

# 実行
python3 add-bastion-access-to-rds-sgs.py
```

### ステップ5: 結果確認

追加されたルールを確認:

```bash
# 特定のセキュリティグループのルールを確認
aws ec2 describe-security-groups \
  --group-ids sg-abc12345 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`]' \
  --output table

# または全セキュリティグループを確認
for sg_id in sg-abc12345 sg-def67890 sg-ghi11111; do
  echo "=== $sg_id ==="
  aws ec2 describe-security-groups \
    --group-ids $sg_id \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`].IpRanges[].[CidrIp,Description]' \
    --output table
done
```

## スクリプトの動作

1. **既存ルールチェック**: 同じCIDRとポートのルールが既に存在する場合はスキップ
2. **エラーハンドリング**: セキュリティグループが見つからない場合はエラーを表示して次へ
3. **統計情報**: 成功/スキップ/エラーの件数を最後に表示

## 追加されるルール

```
Type: Ingress (Inbound)
Protocol: TCP
Port: 3306 (または設定したRDS_PORT)
Source: 10.0.0.0/16 (または設定したBASTION_VPC_CIDR)
Description: Access from Bastion VPC
```

## トラブルシューティング

### 権限エラー

```
An error occurred (UnauthorizedOperation)
```

IAMユーザー/ロールに以下の権限が必要です:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

### セキュリティグループが見つからない

```
An error occurred (InvalidGroup.NotFound)
```

- セキュリティグループIDが正しいか確認
- リージョン設定が正しいか確認
- セキュリティグループが削除されていないか確認

### 重複ルールエラー

```
An error occurred (InvalidPermission.Duplicate)
```

同じルールが既に存在しています。スクリプトは通常これを検出してスキップしますが、
同時実行などで発生する可能性があります。問題ありません。

## 注意事項

- **本番環境での実行前に必ずドライランを実行してください**
- **バックアップ**: セキュリティグループの現在の設定をバックアップすることを推奨
  ```bash
  aws ec2 describe-security-groups --group-ids sg-xxx > sg-backup.json
  ```
- **影響範囲**: このスクリプトはIngressルールのみを追加し、既存ルールは変更しません
- **元に戻す**: 追加したルールを削除する場合:
  ```bash
  aws ec2 revoke-security-group-ingress \
    --group-id sg-xxx \
    --ip-permissions IpProtocol=tcp,FromPort=3306,ToPort=3306,IpRanges='[{CidrIp=10.0.0.0/16}]'
  ```

## ライセンス

MIT License
