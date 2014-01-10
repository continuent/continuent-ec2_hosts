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
      ENV['AWS_ACCESS_KEY'] = Facter.value('aws_access_key')
      ENV['AWS_SECRET_KEY'] = Facter.value('aws_secret_access_key')

      region_index = -1
      region_threads = []
      region_results = []
      regions = `ec2-describe-regions | awk '{print $2}'`.to_s().split("\n")
      regions.each{|r|
        region_threads << Thread.new{
          index = Thread.exclusive{ (region_index = region_index+1) }
          region = regions[index]
          region_results[index] = {}
          Puppet.debug("Collect ec2_hosts from #{region}")

          # Find all instances that have the matching value for the request tag key
          instances = `ec2-describe-tags --region #{region} --filter "resource-type=instance" --filter "key=#{Facter.value('ec2_tag_group_key')}" --filter "value=#{Facter.value('ec2_tag_group_value')}" | cut -f3`.split("\n")
          # Get instance details for all matching instances that are running
          details = `ec2-describe-instances --region #{region} --filter "instance-state-name=running" #{instances.join(' ')}`.split("\n")

          details.each{|info|
            parts = info.split("\t")
            if parts[0] == "RESERVATION"
            elsif parts[0] == "INSTANCE"
              region_results[index][parts[1]] = {} unless region_results[index].has_key?(parts[1])
              region_results[index][parts[1]]['region'] = parts[11]
              region_results[index][parts[1]]['public-address'] = parts[16]
              region_results[index][parts[1]]['private-address'] = parts[17]
            elsif parts[0] == "TAG"
              region_results[index][parts[2]] = {} unless region_results[index].has_key?(parts[2])
              region_results[index][parts[2]]['tags'] = {} unless region_results[index][parts[2]].has_key?('tags')
              region_results[index][parts[2]]['tags'][parts[3]] = parts[4]
            elsif parts[0] == "BLOCKDEVICE"
            end
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