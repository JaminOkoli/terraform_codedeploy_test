#!/bin/bash
sudo apt-get update -y
sudo apt-get install ruby -y
#!/bin/bash
sudo apt-get update -y
sudo apt-get install ruby -y
sudo apt-get install wget -y
cd /home/ubuntu
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
rm install

#!/bin/bash

# Install nginx
sudo apt-get update
sudo apt-get install nginx -y

# Create a new configuration file for the reverse proxy
sudo touch /etc/nginx/sites-available/reverse-proxy

# Write the configuration to the file
sudo echo "server {
    listen 80;
    server_name meetjamin.online.;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}" > /etc/nginx/sites-available/reverse-proxy

# Create a symbolic link to enable the configuration
sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/

# Restart nginx to apply the changes
sudo systemctl restart nginx