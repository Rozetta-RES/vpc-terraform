#!/usr/bin/env python3
"""
RDSインスタンスに紐づいているセキュリティグループを一覧表示するスクリプト
"""

import boto3
import json
from typing import List, Dict
from botocore.exceptions import ClientError

REGION = "ap-northeast-1"


def get_rds_security_groups() -> List[Dict[str, any]]:
    """
    全RDSインスタンスとそれに紐づくセキュリティグループを取得
    
    Returns:
        List[Dict]: RDS情報とセキュリティグループのリスト
    """
    rds_client = boto3.client('rds', region_name=REGION)
    ec2_client = boto3.client('ec2', region_name=REGION)
    
    results = []
    
    try:
        # RDSインスタンス一覧取得
        response = rds_client.describe_db_instances()
        
        for db in response['DBInstances']:
            db_identifier = db['DBInstanceIdentifier']
            db_engine = db['Engine']
            vpc_id = db.get('DBSubnetGroup', {}).get('VpcId', 'N/A')
            
            # セキュリティグループ情報
            sg_ids = [sg['VpcSecurityGroupId'] for sg in db.get('VpcSecurityGroups', [])]
            
            # セキュリティグループ詳細取得
            sg_details = []
            if sg_ids:
                try:
                    sg_response = ec2_client.describe_security_groups(GroupIds=sg_ids)
                    for sg in sg_response['SecurityGroups']:
                        sg_details.append({
                            'id': sg['GroupId'],
                            'name': sg['GroupName'],
                            'description': sg.get('Description', '')
                        })
                except ClientError as e:
                    print(f"警告: SG詳細取得エラー ({db_identifier}): {e}")
            
            results.append({
                'db_identifier': db_identifier,
                'engine': db_engine,
                'vpc_id': vpc_id,
                'security_groups': sg_details
            })
    
    except ClientError as e:
        print(f"エラー: RDS情報取得失敗: {e}")
    
    return results


def print_results(results: List[Dict[str, any]]):
    """結果を見やすく表示"""
    print("=" * 80)
    print("RDS インスタンスとセキュリティグループ一覧")
    print("=" * 80)
    print()
    
    if not results:
        print("RDSインスタンスが見つかりませんでした。")
        return
    
    for idx, rds_info in enumerate(results, 1):
        print(f"{idx}. RDS: {rds_info['db_identifier']}")
        print(f"   Engine: {rds_info['engine']}")
        print(f"   VPC: {rds_info['vpc_id']}")
        print(f"   Security Groups:")
        
        if rds_info['security_groups']:
            for sg in rds_info['security_groups']:
                print(f"     - {sg['id']} ({sg['name']})")
                print(f"       {sg['description']}")
        else:
            print("     (なし)")
        print()
    
    # セキュリティグループIDのリストを出力
    print("-" * 80)
    print("すべてのセキュリティグループID (スクリプトにコピペ用):")
    print("-" * 80)
    
    all_sg_ids = set()
    for rds_info in results:
        for sg in rds_info['security_groups']:
            all_sg_ids.add(sg['id'])
    
    if all_sg_ids:
        print("SECURITY_GROUPS = [")
        for sg_id in sorted(all_sg_ids):
            print(f'    "{sg_id}",')
        print("]")
    else:
        print("(セキュリティグループが見つかりませんでした)")


def export_json(results: List[Dict[str, any]], filename: str = "rds_security_groups.json"):
    """結果をJSONファイルにエクスポート"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print()
        print(f"結果を {filename} にエクスポートしました。")
    except Exception as e:
        print(f"エラー: JSONエクスポート失敗: {e}")


def main():
    """メイン処理"""
    print(f"リージョン: {REGION}")
    print()
    
    # RDS情報取得
    results = get_rds_security_groups()
    
    # 結果表示
    print_results(results)
    
    # JSON出力
    if results:
        export_json(results)


if __name__ == "__main__":
    main()
