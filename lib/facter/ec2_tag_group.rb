# === Copyright
#
# Copyright 2013 Continuent Inc.
#
# === License
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Facter.add(:ec2_tag_group) do
  setcode do
    fact = ""
    if Facter.value('ec2_tag_group_key').to_s() != ""
      begin
        require 'aws/ec2'
      rescue LoadError
        raise "The aws-sdk Ruby gem or rubygem-aws-sdk package is required for this class"
      end
      
      AWS.config({
        :access_key_id => Facter.value('aws_access_key'),
        :secret_access_key => Facter.value('aws_secret_access_key'),
      })
      ec2 = AWS::EC2.new()

      region_index = -1
      region_threads = []
      region_results = []
      regions = ec2.regions.map(&:name)
      regions.each{|r|
        region_threads << Thread.new{
          index = Thread.exclusive{ (region_index = region_index+1) }
          region = regions[index]
          region_results[index] = {}
          Puppet.debug("Collect ec2_hosts from #{region}")
          
          region_ec2 = AWS::EC2.new(:region => region)
          region_ec2.instances().tagged(Facter.value('ec2_tag_group_key')).tagged_values(Facter.value('ec2_tag_group_value')).each{
            |ins|
            unless ins.status == :running
              next
            end
            
            tags = ins.tags.to_h()
            unless tags[Facter.value('ec2_tag_group_key')] == Facter.value('ec2_tag_group_value')
              next
            end
            
            Puppet.debug("Found #{ins.id}")
            region_results[index][ins.id] = {
              'region' => region,
              'az' => ins.availability_zone,
              'public-address' => ins.public_ip_address,
              'private-address' => ins.private_ip_address,
              'tags' => tags,
            }
          }
        }
      }

      region_threads.each{|t| t.join() }

      tag_group = {}
      region_results.each{
        |region_result|
        tag_group = tag_group.merge(region_result)
      }

      if tag_group.keys().size() > 0
        fact = Marshal.dump(tag_group)
      end
    end
    
    fact
  end
end