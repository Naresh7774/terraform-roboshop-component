#!/bin/bash

component=$1
environment=$2
dnf install ansible -y

REPO_URL=https://github.com/daws-86s/ansible-roboshop-roles-tf.git
REPO_DIR=/opt/roboshop/ansible
ANSIBLE_DIR=ansible-roboshop-roles-tf

mkdir -p $REPO_DIR
mkdir -p /var/log/roboshop/
touch ansible.log

