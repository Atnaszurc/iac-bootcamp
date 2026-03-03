#!/bin/bash
# User data script for application servers
# This script runs on instance launch to configure the application

set -e

# Update system packages
yum update -y

# Install application dependencies
yum install -y \
    python3 \
    python3-pip \
    nginx \
    amazon-cloudwatch-agent

# Configure environment
cat > /etc/environment << EOF
ENVIRONMENT=${environment}
DB_ENDPOINT=${db_endpoint}
DB_SECRET_ARN=${db_secret_arn}
EOF

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create a simple health check endpoint
cat > /usr/share/nginx/html/health << 'EOF'
OK
EOF

# Configure nginx
cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Start nginx
systemctl enable nginx
systemctl start nginx

# Log successful startup
echo "Application server started successfully in ${environment} environment" | logger -t user-data

# Made with Bob
