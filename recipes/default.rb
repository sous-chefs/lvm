#
# Cookbook:: lvm
# Recipe:: default
#
# Copyright:: 2009-2017, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package 'lvm2'

# Start+Enable the lvmetad service on RHEL7, it is required by default
# but not automatically started
if node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 7 && !platform?('amazon')
  service 'lvm2-lvmetad' do
    action [:enable, :start]
    provider Chef::Provider::Service::Systemd
    only_if '/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1'
  end
end
