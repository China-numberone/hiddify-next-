#!/bin/bash

# 更新系统，安装基础环境
sudo apt update && sudo apt install -y python3 python3-pip git nginx curl

# 使用官方一键安装脚本部署 Hiddify 服务端
bash -c "$(curl -fsSL https://i.hiddify.com/release)"

# 显示 nginx 状态，确认是否启动
systemctl status nginx --no-pager -n 10

# 显示 Hiddify 面板服务状态（如果有）
systemctl status hiddify-panel --no-pager -n 10 || echo "hiddify-panel 服务未找到"

echo "安装完成，请根据提示访问面板地址。"

# 退出到上级目录
cd ..

# 创建 nginx 配置文件
sudo tee /etc/nginx/conf.d/hiddify-next.conf > /dev/null << EOF
server {
    listen 8443 ssl;
    listen [::]:8443 ssl;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:1717;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://\$host:8443\$request_uri;
}
EOF

# 测试 nginx 配置并重载
sudo nginx -t && sudo systemctl reload nginx

# 启动 Flask 服务（建议用 nohup 后台运行或者写 systemd 服务）
cd hiddify-next

# 这里改端口为1717，和nginx代理端口对应
nohup flask run --host=127.0.0.1 --port=1717 > flask.log 2>&1 &

echo "启动完成，nginx 代理端口 8443 -> Flask 服务 127.0.0.1:1717"
echo "如果需要停止 flask 服务，请用 'pkill -f flask'"
