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
    if Facter.value('ec2_tag_group_key').to_s() != ""
      ENV['AWS_ACCESS_KEY'] = Facter.value('aws_access_key')
      ENV['AWS_SECRET_KEY'] = Facter.value('aws_secret_access_key')
    
      regions = Facter.value('ec2_tag_regions').to_s()
      if regions == ""
        regions = "us-east-1"
      end
      
      tag_group = {}
      regions.split(",").each{
        |region|
        
        # Fina all instances that have the matching value for the request tag key
        instances = `ec2-describe-tags --region #{region} --filter "resource-type=instance" --filter "key=#{Facter.value('ec2_tag_group_key')}" --filter "value=#{Facter.value('ec2_tag_group_value')}" | cut -f3`.split("\n")
        # Get instance details for all matching instances that are running
        details = `ec2-describe-instances --region #{region} --filter "instance-state-name=running" #{instances.join(' ')}`.split("\n")

        details.each{|info|
          parts = info.split("\t")
          if parts[0] == "RESERVATION"
          elsif parts[0] == "INSTANCE"
            tag_group[parts[1]] = {} unless tag_group.has_key?(parts[1])
            tag_group[parts[1]]['region'] = parts[11]
            tag_group[parts[1]]['public-address'] = parts[16]
            tag_group[parts[1]]['private-address'] = parts[17]
          elsif parts[0] == "TAG"
            tag_group[parts[2]] = {} unless tag_group.has_key?(parts[2])
            tag_group[parts[2]]['tags'] = {} unless tag_group[parts[2]].has_key?('tags')
            tag_group[parts[2]]['tags'][parts[3]] = parts[4]
          elsif parts[0] == "BLOCKDEVICE"
          end
        }
      }
      
      if tag_group.keys().size() == 0
        ""
      else
        Marshal.dump(tag_group)
      end
    else
      ""
    end
  end
end