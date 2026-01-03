#!/bin/bash
set -e  # Exit on error

# 捕获错误，确保主程序能启动
handle_error() {
    echo "Error occurred in setup script. Starting application anyway..."
    python main.py
}
trap 'handle_error' ERR

# 如果存在 RCLON_CONF 环境变量，则配置 rclone
if [ -n "$RCLON_CONF" ]; then
    echo "Configuring rclone..."
    mkdir -p /home/user/.config/rclone
    
    # 先写入临时文件
    echo "$RCLON_CONF" > /home/user/.config/rclone/rclone.conf.tmp
    
    # 提取配置信息 (简单的 grep/cut 解析)
    TYPE=$(grep "type =" /home/user/.config/rclone/rclone.conf.tmp | cut -d= -f2 | xargs || echo "")
    URL=$(grep "url =" /home/user/.config/rclone/rclone.conf.tmp | cut -d= -f2 | xargs || echo "")
    VENDOR=$(grep "vendor =" /home/user/.config/rclone/rclone.conf.tmp | cut -d= -f2 | xargs || echo "")
    USER_NAME=$(grep "user =" /home/user/.config/rclone/rclone.conf.tmp | cut -d= -f2 | xargs || echo "")
    PASS=$(grep "pass =" /home/user/.config/rclone/rclone.conf.tmp | cut -d= -f2 | xargs || echo "")
    
    # 使用 rclone config create 重新生成配置 (会自动处理密码加密)
    if [ -n "$PASS" ]; then
        echo "Re-creating rclone config to ensure password is obscured..."
        rclone config create infini_dav "$TYPE" url "$URL" vendor "$VENDOR" user "$USER_NAME" pass "$PASS" --non-interactive || echo "Rclone config creation failed"
    else
        # 如果没有密码字段，直接使用原文件
        mv /home/user/.config/rclone/rclone.conf.tmp /home/user/.config/rclone/rclone.conf || echo "Failed to move config file"
    fi
    
    # 尝试从远程恢复数据
    echo "Restoring data from remote..."
    rclone copy infini_dav:flow2api_data /app/data --ignore-existing || echo "Failed to restore data (this is normal for first run)"
    
    # 启动后台同步进程 (每15分钟同步一次)
    echo "Starting background sync..."
    (
        while true; do
            sleep 900
            # 同步 data 目录到远程
            rclone sync /app/data infini_dav:flow2api_data || echo "Background sync failed"
        done
    ) &
fi

# 启动主程序
echo "Starting application..."
python main.py
