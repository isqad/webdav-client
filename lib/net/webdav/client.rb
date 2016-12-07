require 'uri'
require 'curb'

module Net
  module Webdav
    class Client
      # Public: maximum time to execution of request in seconds
      MAX_TIMEOUT = 30

      attr_reader :host, :username, :password, :url, :http_auth_types, :timeout

      def initialize(url, options = {})
        uri = URI.parse(url)

        @host = "#{uri.scheme}://#{uri.host}#{uri.port.nil? ? "" : ":#{uri.port}"}"
        @http_auth_types = options[:http_auth_types] || :basic

        if uri.userinfo
          @username, @password = uri.userinfo.split(":")
        else
          @username = options[:username]
          @password = options[:password]
        end

        @url = URI.join(@host, uri.path)

        @timeout = options.fetch(:timeout, MAX_TIMEOUT)
      end

      # Public: HEAD, check if file exists
      #
      # path - String, path to file on server
      #
      # Returns: Boolean
      def file_exists?(path)
        connection = curl(path)
        connection.http_head

        connection.response_code >= 200 && connection.response_code < 300
      end

      # Public: GET file, saves path to local_file_path
      #
      # path - String, path to file on server
      # local_file_path - String, file path to save on disk
      #
      # Returns: nothing
      def get_file(path, local_file_path)
        file = output_file(local_file_path)

        connection = curl(path)
        connection.perform

        notify_of_error(connection, "getting file. #{path}") if connection.response_code != 200

        file.write(connection.body_str)
      ensure
        file.close
      end

      # Public: PUT file
      #
      # path - String, path to file on server
      # file - File, file for save on server
      # crate_path - Boolean, true if need create path
      #
      # Returns Fixnum, status code, 201 || 204, if success
      def put_file(path, file, create_path = false)
        connection = curl(path)

        if create_path
          uri = URI.parse(full_url(path))
          path_parts = uri.path.split('/').reject { |s| s.to_s.empty? }
          path_parts.pop

          for i in 0..(path_parts.length - 1)
            # if the part part is for a file with an extension skip
            next unless File.extname(path_parts[i]).empty?

            parent_path = path_parts[0..i].join('/')
            url = URI.join(
              "#{uri.scheme}://#{uri.host}#{(uri.port.nil? || uri.port == 80) ? "" : ":#{uri.port}"}/", parent_path
            )

            connection.url = full_url(url)
            connection.http(:MKCOL)

            notify_of_error(connection, "creating directories") unless [201, 204, 405].include?(connection.response_code)

            # 201 Created or 405 Conflict (already exists)
            return connection.response_code if connection.response_code != 201 && connection.response_code != 405
          end
        end

        connection.url = full_url(path)
        connection.http_put(file)

        if connection.response_code != 201 && connection.response_code != 204
          notify_of_error(connection, "creating(putting) file. File path: #{path}")
        end

        connection.response_code
      end

      # Public: DELETE file by path
      #
      # path - String, path to file on server
      #
      # Throws Curl::Err
      #
      # Returns Boolean, always true
      def delete_file(path)
        curl(path).http_delete
      end

      # Public: MKCOL make directory on server
      #
      # path - String, path to directory on server
      #
      # Returns Curl::Easy
      def make_directory(path)
        connection = curl(path)
        connection.http(:MKCOL)
        connection
      end

      private

      def curl(uri)
        raise ArgumentError, "Wrong path #{uri}" if uri.to_s.empty? || uri.to_s == '/'.freeze

        connection = ::Curl::Easy.new
        connection.url = full_url(uri)
        connection.http_auth_types = http_auth_types if http_auth_types
        connection.userpwd = curl_credentials if username && password
        connection.timeout = timeout

        connection
      end

      def notify_of_error(connection, action)
        raise "Error in WEBDav Client while #{action} with error: #{connection.status}"
      end

      def curl_credentials
        "#{@username}:#{@password}"
      end

      def full_url(path)
        URI.join(@url, path).to_s
      end

      def output_file(filename)
        if filename.is_a? IO
          filename.binmode if filename.respond_to?(:binmode)
          filename
        else
          File.open(filename, 'wb')
        end
      end
    end
  end
end
