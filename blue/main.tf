provider "aws" {
  region ="eu-north-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name    = "name"
    values  = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instace" "app-blue"{
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  subnet_id       = data.aws_subnets.default_ids[0]
  security_groups = [aws_security_group.ec2.id]

  #user_data = file("user_data.sh")
  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Images!</h1></br>
             <h3>(Instance B)</h3>
             </html>' | sudo tee /var/www/html/index.html
             echo 'server {
                       listen 80 default_server;
                       listen [::]:80 default_server;
                       root /var/www/html;
                       index index.html index.htm index.nginx-debian.html;
                       server_name _;
                       location /images/ {
                           alias /var/www/html/;
                           index index.html;
                       }
                       location / {
                           try_files $uri $uri/ =404;
                       }
                   }' | sudo tee /etc/nginx/sites-available/default
             sudo systemctl reload nginx
             EOF

  tags = {
    Name = "app-blue"
  }
}