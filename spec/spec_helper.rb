# coding: utf-8

require 'simplecov'
SimpleCov.start do
  minimum_coverage 95
end

require 'net/webdav/client'
require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:suite) do
    WebMock.disable_net_connect!(allow: 'web')
  end
end
