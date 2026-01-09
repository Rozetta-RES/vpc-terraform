#!/bin/bash

# =============================================================================
# RDSセキュリティグループに踏み台VPC CIDRアクセスを追加するスクリプト
# =============================================================================

set -e

# 設定値
BASTION_VPC_CIDR="10.0.0.0/16"  # 踏み台VPC CIDR (要変更)
RDS_PORT=3306  # MySQL/Aurora (PostgreSQLの場合は5432に変更)
REGION="ap-northeast-1"

# 対象のセキュリティグループID (要変更)
SECURITY_GROUPS=(
    "sg-xxxxxxxxx1"
    "sg-xxxxxxxxx2"
    "sg-xxxxxxxxx3"
)

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ドライランモード (実行時は DRY_RUN=false に変更)
DRY_RUN=true

echo "==================================================="
echo "RDS セキュリティグループ更新スクリプト"
echo "==================================================="
echo ""
echo "設定:"
echo "  踏み台VPC CIDR: ${BASTION_VPC_CIDR}"
echo "  RDSポート: ${RDS_PORT}"
echo "  リージョン: ${REGION}"
echo "  ドライランモード: ${DRY_RUN}"
echo ""
echo "対象セキュリティグループ数: ${#SECURITY_GROUPS[@]}"
echo ""

# 確認
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}警告: 実際にセキュリティグループを更新します。${NC}"
    read -p "続行しますか? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "キャンセルしました。"
        exit 0
    fi
fi

SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# 各セキュリティグループに対して処理
for SG_ID in "${SECURITY_GROUPS[@]}"; do
    echo "---------------------------------------------------"
    echo -e "処理中: ${GREEN}${SG_ID}${NC}"
    
    # セキュリティグループ情報を取得
    SG_INFO=$(aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --region "$REGION" \
        2>/dev/null || echo "ERROR")
    
    if [ "$SG_INFO" = "ERROR" ]; then
        echo -e "${RED}✗ エラー: セキュリティグループ ${SG_ID} が見つかりません${NC}"
        ((ERROR_COUNT++))
        continue
    fi
    
    SG_NAME=$(echo "$SG_INFO" | jq -r '.SecurityGroups[0].GroupName')
    VPC_ID=$(echo "$SG_INFO" | jq -r '.SecurityGroups[0].VpcId')
    
    echo "  名前: ${SG_NAME}"
    echo "  VPC: ${VPC_ID}"
    
    # 既存ルールをチェック
    EXISTING_RULE=$(echo "$SG_INFO" | jq -r \
        --arg cidr "$BASTION_VPC_CIDR" \
        --arg port "$RDS_PORT" \
        '.SecurityGroups[0].IpPermissions[] | 
        select(.FromPort == ($port | tonumber) and .ToPort == ($port | tonumber)) | 
        .IpRanges[] | 
        select(.CidrIp == $cidr) | 
        .CidrIp' 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_RULE" ]; then
        echo -e "${YELLOW}  → ルールは既に存在します (スキップ)${NC}"
        ((SKIP_COUNT++))
        continue
    fi
    
    # ルールを追加
    if [ "$DRY_RUN" = true ]; then
        echo -e "${GREEN}  → [DRY RUN] ルールを追加します${NC}"
        echo "     aws ec2 authorize-security-group-ingress \\"
        echo "       --group-id ${SG_ID} \\"
        echo "       --ip-permissions IpProtocol=tcp,FromPort=${RDS_PORT},ToPort=${RDS_PORT},IpRanges='[{CidrIp=${BASTION_VPC_CIDR},Description=\"Access from Bastion VPC\"}]' \\"
        echo "       --region ${REGION}"
        ((SUCCESS_COUNT++))
    else
        RESULT=$(aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --ip-permissions "IpProtocol=tcp,FromPort=${RDS_PORT},ToPort=${RDS_PORT},IpRanges=[{CidrIp=${BASTION_VPC_CIDR},Description='Access from Bastion VPC'}]" \
            --region "$REGION" \
            2>&1 || echo "ERROR")
        
        if [[ "$RESULT" == *"ERROR"* ]]; then
            echo -e "${RED}  ✗ エラー: ルール追加失敗${NC}"
            echo "     ${RESULT}"
            ((ERROR_COUNT++))
        else
            echo -e "${GREEN}  ✓ ルールを追加しました${NC}"
            ((SUCCESS_COUNT++))
        fi
    fi
done

echo ""
echo "==================================================="
echo "処理完了"
echo "==================================================="
echo -e "成功: ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "スキップ (既存): ${YELLOW}${SKIP_COUNT}${NC}"
echo -e "エラー: ${RED}${ERROR_COUNT}${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}※ これはドライランです。実際に実行する場合は、${NC}"
    echo -e "${YELLOW}   スクリプト内の DRY_RUN=false に変更してください。${NC}"
fi
