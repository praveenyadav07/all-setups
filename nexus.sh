#!/bin/bash

# Update and install required packages
sudo yum update -y
sudo yum install wget -y
sudo yum install java-17-amazon-corretto -y  # full JDK, not just jmods

# Create application directory
sudo mkdir -p /app && cd /app

# Download and extract Nexus
sudo wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.79.0-09.tar.gz
sudo tar -xvf nexus.tar.gz
sudo mv nexus-3* nexus

# Create Nexus user
sudo adduser --system --no-create-home --shell /bin/false nexus

# Create required directories
sudo mkdir -p /app/sonatype-work

# Set ownership
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work

# Set run_as_user in nexus.rc
echo 'run_as_user="nexus"' | sudo tee /app/nexus/bin/nexus.rc > /dev/null

# Set JAVA_HOME in nexus script
sudo sed -i '2i export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64' /app/nexus/bin/nexus

# Make sure nexus script is executable
sudo chmod +x /app/nexus/bin/nexus

# Create systemd service file
sudo tee /etc/systemd/system/nexus.service > /dev/null << EOL
[Unit]
Description=Nexus Service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start Nexus
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Check status
sudo systemctl status nexus
