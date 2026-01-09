#!/usr/bin/env python3
"""
RDSセキュリティグループに踏み台VPC CIDRアクセスを追加するスクリプト
"""

import boto3
import sys
from typing import List, Dict
from botocore.exceptions import ClientError

# =============================================================================
# 設定値
# =============================================================================
BASTION_VPC_CIDR = "10.0.0.0/16"  # 踏み台VPC CIDR (要変更)
RDS_PORT = 3306  # MySQL/Aurora (PostgreSQLの場合は5432に変更)
REGION = "ap-northeast-1"

# 対象のセキュリティグループID (要変更)
SECURITY_GROUPS = [
    "sg-xxxxxxxxx1",
    "sg-xxxxxxxxx2",
    "sg-xxxxxxxxx3",
]

# ドライランモード (実行時は False に変更)
DRY_RUN = True

# =============================================================================
# カラー出力
# =============================================================================
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def print_header(message: str):
    """ヘッダーを出力"""
    print("=" * 60)
    print(message)
    print("=" * 60)


def print_section(message: str):
    """セクション区切りを出力"""
    print("-" * 60)
    print(message)


def check_existing_rule(ec2_client, sg_id: str) -> bool:
    """
    指定されたセキュリティグループに既にルールが存在するかチェック
    
    Args:
        ec2_client: boto3 EC2クライアント
        sg_id: セキュリティグループID
        
    Returns:
        bool: ルールが存在する場合True
    """
    try:
        response = ec2_client.describe_security_groups(GroupIds=[sg_id])
        sg = response['SecurityGroups'][0]
        
        for permission in sg.get('IpPermissions', []):
            if permission.get('FromPort') == RDS_PORT and permission.get('ToPort') == RDS_PORT:
                for ip_range in permission.get('IpRanges', []):
                    if ip_range.get('CidrIp') == BASTION_VPC_CIDR:
                        return True
        return False
        
    except ClientError as e:
        print(f"{Colors.RED}エラー: {e}{Colors.NC}")
        return False


def add_ingress_rule(ec2_client, sg_id: str, sg_name: str, vpc_id: str) -> Dict[str, any]:
    """
    セキュリティグループにIngressルールを追加
    
    Args:
        ec2_client: boto3 EC2クライアント
        sg_id: セキュリティグループID
        sg_name: セキュリティグループ名
        vpc_id: VPC ID
        
    Returns:
        Dict: 処理結果 {status: 'success'|'skip'|'error', message: str}
    """
    print(f"  名前: {sg_name}")
    print(f"  VPC: {vpc_id}")
    
    # 既存ルールチェック
    if check_existing_rule(ec2_client, sg_id):
        message = f"{Colors.YELLOW}  → ルールは既に存在します (スキップ){Colors.NC}"
        print(message)
        return {'status': 'skip', 'message': message}
    
    # ルール追加
    if DRY_RUN:
        message = f"{Colors.GREEN}  → [DRY RUN] ルールを追加します{Colors.NC}"
        print(message)
        print(f"     CidrIp: {BASTION_VPC_CIDR}")
        print(f"     Port: {RDS_PORT}")
        return {'status': 'success', 'message': message}
    else:
        try:
            ec2_client.authorize_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=[
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': RDS_PORT,
                        'ToPort': RDS_PORT,
                        'IpRanges': [
                            {
                                'CidrIp': BASTION_VPC_CIDR,
                                'Description': 'Access from Bastion VPC'
                            }
                        ]
                    }
                ]
            )
            message = f"{Colors.GREEN}  ✓ ルールを追加しました{Colors.NC}"
            print(message)
            return {'status': 'success', 'message': message}
            
        except ClientError as e:
            message = f"{Colors.RED}  ✗ エラー: {e}{Colors.NC}"
            print(message)
            return {'status': 'error', 'message': str(e)}


def main():
    """メイン処理"""
    print_header("RDS セキュリティグループ更新スクリプト")
    print()
    print("設定:")
    print(f"  踏み台VPC CIDR: {BASTION_VPC_CIDR}")
    print(f"  RDSポート: {RDS_PORT}")
    print(f"  リージョン: {REGION}")
    print(f"  ドライランモード: {DRY_RUN}")
    print()
    print(f"対象セキュリティグループ数: {len(SECURITY_GROUPS)}")
    print()
    
    # 確認
    if not DRY_RUN:
        print(f"{Colors.YELLOW}警告: 実際にセキュリティグループを更新します。{Colors.NC}")
        confirm = input("続行しますか? (yes/no): ")
        if confirm.lower() != 'yes':
            print("キャンセルしました。")
            sys.exit(0)
    
    # EC2クライアント作成
    ec2_client = boto3.client('ec2', region_name=REGION)
    
    # 統計
    stats = {
        'success': 0,
        'skip': 0,
        'error': 0
    }
    
    # 各セキュリティグループを処理
    for sg_id in SECURITY_GROUPS:
        print_section(f"処理中: {Colors.GREEN}{sg_id}{Colors.NC}")
        
        try:
            # セキュリティグループ情報取得
            response = ec2_client.describe_security_groups(GroupIds=[sg_id])
            sg = response['SecurityGroups'][0]
            
            sg_name = sg['GroupName']
            vpc_id = sg['VpcId']
            
            # ルール追加
            result = add_ingress_rule(ec2_client, sg_id, sg_name, vpc_id)
            stats[result['status']] += 1
            
        except ClientError as e:
            if 'InvalidGroup.NotFound' in str(e):
                print(f"{Colors.RED}✗ エラー: セキュリティグループ {sg_id} が見つかりません{Colors.NC}")
            else:
                print(f"{Colors.RED}✗ エラー: {e}{Colors.NC}")
            stats['error'] += 1
        
        print()
    
    # 結果サマリー
    print_header("処理完了")
    print(f"成功: {Colors.GREEN}{stats['success']}{Colors.NC}")
    print(f"スキップ (既存): {Colors.YELLOW}{stats['skip']}{Colors.NC}")
    print(f"エラー: {Colors.RED}{stats['error']}{Colors.NC}")
    print()
    
    if DRY_RUN:
        print(f"{Colors.YELLOW}※ これはドライランです。実際に実行する場合は、{Colors.NC}")
        print(f"{Colors.YELLOW}   スクリプト内の DRY_RUN = False に変更してください。{Colors.NC}")


if __name__ == "__main__":
    main()
