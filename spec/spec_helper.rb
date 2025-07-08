# frozen_string_literal: true

require_relative '../app/constants'
require_relative '../app/errors'

["services", "models", "utils", "api"].each do |dir|
  Dir[File.join(__dir__, "../app/#{dir}/**/*.rb")].each { |file| require file }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
