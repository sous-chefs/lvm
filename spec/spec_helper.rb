# frozen_string_literal: true
#
# spec/spec_helper.rb
#
# Uses gems bundled with Chef Workstation — no Gemfile needed.
# Run tests with:  chef exec rspec spec/

require 'chefspec'
require 'chefspec/berkshelf' if File.exist?('Berksfile')

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  # Default platform for all ChefSpec examples unless overridden per-context.
  config.platform  = 'redhat'
  config.version   = '9.0'
end
