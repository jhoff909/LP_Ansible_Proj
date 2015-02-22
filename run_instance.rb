#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

# Get an ec2 client in the Oregon region (a bit cheaper than N. CA)
ec2 = Aws::EC2::Client.new(region:'us-west-2')

# Spin up a new instance using the Ubuntu 14.04 AMI
# Uses the "Apache" security group and the "Apache" key pair
# Could spin up more than one... 
instance = ec2.run_instances(
:image_id => 'ami-29ebb519',
:instance_type => 't2.micro',
:min_count => 1,
:max_count => 1,
:security_group_ids => ['sg-5c133739'],
:subnet_id => 'subnet-c91cefbe',
:key_name => 'Apache')

id = instance.instances[0].instance_id
puts "Instance ID: " + id

# Add a tag with type=web so we can keep track of these
ec2.create_tags(
:resources => [id],
:tags => [ { :key => 'type', :value => 'web' } ] )

# Wait for the instance to start...
sleep 10 while ec2.describe_instances(:instance_ids => [id]).reservations[0].instances[0].state.name == "pending"

# Get the public DNS name of the new instance
public_dns_name = ec2.describe_instances(:instance_ids => [id]).reservations[0].instances[0].public_dns_name

# Write the DNS name in the [web] section of the hosts file for ansible to use
hosts = File.open("hosts", "r")
contents = hosts.read
hosts.close

hosts = File.open("hosts", "w")
contents.each_line do |line|
  hosts.print line
  if line == "[web]\n"
      hosts.puts public_dns_name
  end
end

hosts.close

# Wait for the host to actually be reachable
`nc -z -w 10 #{public_dns_name} 22`
while $?.to_i != 0 do
  puts "waiting for #{public_dns_name} to be reachable"
  `nc -z -w 30 #{public_dns_name} 22`
end

ansible_out = `ansible-playbook -s -u ubuntu --inventory-file=./hosts apache2.yml`
puts ansible_out
