本リソースの目的
  他 VPC で稼働中の RDS インスタンスに接続する踏み台環境の構築

セットアップ手順

1. terraform-backend-setup ディレクトリ内で terraform init、plan、apply を実行
→ terraform の state を s3、DyamoDB で管理するリソースをデプロイする

2. vpc/production/bastion-vpc/ 内のリソースをデプロイ
→ VPC を作成するリソース群をデプロイする。

まず、backend.hcl.example を backend.hcl にコピーし、bucket = "terraform-state-862763484576" を記述する
$ cp backend.hcl.example backend.hcl

variables.tf を一通り確認し、問題なければ terraform init、plan、apply を実行

3. ec2/production/bastion 内のリソースをデプロイ
→ 踏み台サーバーを作成するリソース群をデプロイする。

本来は terraform.tfvars.example を terraform.tfvars として作成し、各変数を環境に合わせてデプロイすべきだが
variables.tf を作成しているので、variables.tf に問題がなければそのまま terraform init、plan、apply を実行する

4. vpc/production/vpc-peering 内のリソースをデプロイ
(後日記載予定)