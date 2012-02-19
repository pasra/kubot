require 'rspec'
$:.unshift File.expand_path("#{File.dirname(__FILE__)}/../lib")

module Kubot
  MOCK_PATH = "#{File.dirname(__FILE__)}/mock_bots"
  MOCK_LOAD_PATH = [MOCK_PATH]
end
