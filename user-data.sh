#! /bin/bash
dnf update -y
dnf install pip -y
pip3 install flask
pip3 install flask-mysql
dnf install git -y
TOKEN=${git-token}
USER=${git-name}
cd /home/ec2-user && git clone https://$TOKEN@github.com/$USER/phonebook.git
python3 /home/ec2-user/phonebook/phonebook-app.py
