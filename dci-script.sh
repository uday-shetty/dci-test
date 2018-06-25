#!/bin/bash

sudo apt-get update
sudo apt-get install -y software-properties-common

sudo apt-get install -y unzip
wget https://releases.hashicorp.com/terraform/0.11.5/terraform_0.11.5_linux_amd64.zip
unzip terraform_0.11.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

sudo apt-get update
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get install -y ansible
ansible --version
