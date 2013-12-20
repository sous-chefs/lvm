#
# Cookbook Name:: fake
# Library:: helper
#
# Copyright (C) 2013 Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module LvmTest
  # Helper definitions for lvmtest
  module Helper
    # Creates given loop devices
    #
    # @param devices [Integer] the devices to create
    #
    def self.create_loop_devices(devices)
      Array(devices).each do |device|
        num = device.slice(/\d+/)
        mk_vfile_cmd = "dd if=/dev/zero of=/vfile#{num} bs=1024 count=65536"
        Mixlib::ShellOut.new(mk_vfile_cmd).run_command.error!
        mk_loop_dev_cmd = "losetup #{device} /vfile#{num}"
        Mixlib::ShellOut.new(mk_loop_dev_cmd).run_command.error!
      end
    end

    # Removes the given loop devices
    #
    # @param devices [Array, String] list of loop devices to remove
    #
    def self.remove_loop_devices(devices)
      require 'fileutils'
      Array(devices).each do |device|
        Chef::Log.info "Removing loop device: #{device}"
        num = device.slice(/\d+/)
        Mixlib::ShellOut.new("losetup -d #{device}").run_command.error!
        FileUtils.rm_rf("/vfile#{num}")
      end
    end
  end
end
