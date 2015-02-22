# LP_Ansible_Proj
Script to create AWS instance, install Apache using Ansible: run_instance.rb
Script to terminate an instance that has a tag "type=web": terminate_instance.rb

expects your aws credentials in ~/.aws/credentials
expects ssh keys setup (private key in ~/.ssh/id_rsa)
expects the file ~/.ssh/config to contain the line "StrictHostKeyChecking no"
