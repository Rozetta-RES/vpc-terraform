#!/bin/bash
# ============================================
# Bastion Host Initial Setup Script
# ============================================

set -e

# ログ出力設定
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting initial setup for ${project_name} bastion host..."

# システムアップデート
echo "Updating system packages..."
dnf update -y

# 基本ツールのインストール
echo "Installing basic tools..."
dnf install -y \
    git \
    vim \
    curl \
    wget \
    jq \
    unzip \
    tar \
    htop

# AWS CLI v2 の確認（Amazon Linux 2023にはプリインストール済み）
echo "Checking AWS CLI version..."
aws --version

# タイムゾーンを日本時間に設定
echo "Setting timezone to Asia/Tokyo..."
timedatectl set-timezone Asia/Tokyo

# ホスト名の設定
echo "Setting hostname..."
hostnamectl set-hostname ${project_name}-bastion

echo "Initial setup completed successfully!"
