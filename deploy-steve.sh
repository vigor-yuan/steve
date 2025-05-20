#!/bin/bash

# 部署 SteVe 应用的脚本
# 此脚本应该放在远程服务器上，并通过 GitHub Actions 工作流调用

# 设置变量
TOMCAT_HOME="/opt/tomcat"  # Tomcat 安装目录，根据实际情况修改
BACKUP_DIR="/opt/backups"  # 备份目录
STEVE_WAR="steve.war"      # WAR 文件名
DATE=$(date +"%Y%m%d_%H%M%S")

# 确保备份目录存在
mkdir -p $BACKUP_DIR

# 停止 Tomcat 服务
echo "正在停止 Tomcat 服务..."
sudo systemctl stop tomcat

# 备份当前版本（如果存在）
if [ -f "$TOMCAT_HOME/webapps/$STEVE_WAR" ]; then
  echo "备份当前版本..."
  cp "$TOMCAT_HOME/webapps/$STEVE_WAR" "$BACKUP_DIR/steve_$DATE.war"
fi

# 删除旧的解压目录（如果存在）
if [ -d "$TOMCAT_HOME/webapps/steve" ]; then
  echo "删除旧的解压目录..."
  rm -rf "$TOMCAT_HOME/webapps/steve"
fi

# 部署新版本
echo "部署新版本..."
cp "$STEVE_WAR" "$TOMCAT_HOME/webapps/"

# 启动 Tomcat 服务
echo "启动 Tomcat 服务..."
sudo systemctl start tomcat

# 等待应用启动
echo "等待应用启动..."
sleep 30

# 检查应用是否成功启动
if curl -s http://localhost:8080/steve/manager | grep -q "SteVe"; then
  echo "SteVe 应用已成功部署和启动！"
else
  echo "警告：SteVe 应用可能未成功启动，请检查日志。"
  echo "Tomcat 日志位置: $TOMCAT_HOME/logs/catalina.out"
fi

echo "部署完成！"
