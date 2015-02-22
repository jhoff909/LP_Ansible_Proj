#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

# Get an ec2 client in the Oregon region (a bit cheaper than N. CA)
ec2 = Aws::EC2::Client.new(region:'us-west-2')

# Get the instances with the tag "type" with value "web"
ds = ec2.describe_instances(
:filters => [ {:name => "tag:type", :values => [ "web" ] } ] )

public_dns_names = []
instance_ids = []
index = 1

# Don't entirely understand this data structure - each instance
# seems to be contained by itself in a instances array which is contained
# by itself in a reservations array.  In other words, each reservation
# contains an instances array which contains one instance.  Maybe if I
# provision more than one instance at a time?
puts "Which instanced would you like to terminate:"
ds.reservations.each do |reservation|
  reservation.instances.each do |instance|
    # show each non-terminated instance which had a tag type=web
    if instance.state.name != "terminated" then
      puts index.to_s + ") " + instance.instance_id + "(" + instance.state.name + ")"
      instance_ids << instance.instance_id
      public_dns_names << instance.public_dns_name
      index += 1
    end
  end
end
print "?"
i = gets.chomp.to_i - 1

abort("Invalid input") if i < 0 or i > instance_ids.length - 1

# Terminate the instance
instance = ec2.terminate_instances(
:instance_ids => [instance_ids[i]])

# Wait for the instance to be terminated - do I really need to wait?
sleep 10 while ec2.describe_instances(:instance_ids => [instance_ids[i]]).reservations[0].instances[0].state.name != "terminated"
puts "Terminated " + instance_ids[i]

# Remove the host from the hosts file too
hosts = File.open("hosts", "r")
contents = hosts.read
hosts.close

hosts = File.open("hosts", "w")
contents.each_line do |line|
  next if line == public_dns_names[i] + "\n"
  hosts.print line
end
hosts.close
