# coding: utf-8
require 'sinatra/base'

class TimeoutServer < Sinatra::Base
  set :environment, :production
  set :port, 4567

  head '/system/foo.txt' do
    sleep 2
    [200, {}, '']
  end

  get '/system/foo.txt' do
    sleep 2
    [200, {}, 'abcd']
  end

  put '/system/foo.txt' do
    sleep 2
    [201, {}, '']
  end

  delete '/system/foo.txt' do
    sleep 2
    [200, {}, '']
  end
end

TimeoutServer.run!
