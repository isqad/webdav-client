# Webdav client

Ruby client for WEBDav protocol

## Install

Installing the gem:

```
  gem install webdav-client
```

## Usage

```ruby
  require 'webdav-client'

  client = Net::Webdav::Client.new(
    'https://static-example.com',
     username: 'user',
     password: 'qwerty',
     timeout: 60
  )

  # GET file
  client.get_file('/system/foo.txt', '/tmp/foo.txt')

  # HEAD file
  client.file_exists?('/system/foo.txt')

  # PUT file (with create direcory if set flag
  f = File.new('/tmp/foo.txt', 'r')
  need_create_path = true
  client.put_file('/system/foo.txt', f, need_create_path)
  f.close

  # DELETE file
  client.delete_file('/system/foo.txt')

  # MKCOL - make directory
  client.make_directory('/system')
```

## Tests

You should install docker, dip and docker-compose before

https://github.com/bibendi/dip/releases
https://docs.docker.com/engine/installation/
https://docs.docker.com/compose/install/

```
  $ dip provision
  $ dip rspec
```

