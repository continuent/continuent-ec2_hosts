# ec2_hosts

Write private IP address to /etc/hosts for a set of EC2 servers based on a tag key=>value combination

# Usage

This module uses Facter to load information about matching EC2 servers. Add these values to the facts passed into Puppet.

* "aws_access_key" => "ACCESS_KEY"
* "aws_secret_access_key" => "SECRET_ACCESS_KEY"
* "ec2_tag_group_key" => "HostnameGroup"
* "ec2_tag_group_value" => "DatabasesGroup"

Add the ec2_hosts class to your manifest. You can optionally include the first portion of the hostname in /etc/hosts.

    class { "ec2_hosts": 
  		include_short_hostname => true
  	}