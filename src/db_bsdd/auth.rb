# frozen_string_literal: true

# auth.rb

# Copyright (c) 2022 DigiBase B.V.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'uri'
require 'securerandom'
require 'socket'
require 'net/http'
require 'json'

# https://www.hschne.at/2021/02/26/cli-oauth-in-ruby.html
# https://docs.microsoft.com/nl-nl/azure/active-directory-b2c/authorization-code-flow

module DigiBase
  module BSDD
    class Authentication
      AUTH_BASE_URI = 'https://buildingsmartservices.b2clogin.com/buildingsmartservices.onmicrosoft.com/b2c_1a_signupsignin_c/oauth2/v2.0/'
      AUTH_CODE_URI = AUTH_BASE_URI + 'authorize'
      AUTH_TOKEN_URI = AUTH_BASE_URI + 'token'
      CLIENT_ID = '4aba821f-d4ff-498b-a462-c2837dbbba70'

      def initialize; end

      def token
        @token || authenticate
      end

      private

      def authenticate
        @server = TCPServer.new 0
        @redirect_uri = "http://localhost:#{@server.addr[1]}"
        @state = SecureRandom.uuid

        code = get_authorization_code
        @token = get_token(code)
      rescue StandardError
        false
      end

      def get_authorization_code
        uri = URI(AUTH_CODE_URI)
        uri.query = URI.encode_www_form(
          {
            "client_id": CLIENT_ID,
            "response_type": 'code',
            # offline_access required to get a refresh_token
            "scope": 'https://buildingsmartservices.onmicrosoft.com/api/read offline_access',
            "state": @state,
            "redirect_uri": @redirect_uri
          }
        )
        status = UI.openURL(uri.to_s)

        # https://stackoverflow.com/questions/14250517/making-a-timer-in-ruby
        listen = Thread.new do
          loop do
            client = @server.accept # Wait for a client to connect
            method, path = client.gets.split
            Thread.current[:value] = Hash[URI.decode_www_form(path.split('?')[1])]
            resp = 'Logged into buildingSMART Data Dictionary, you may now close this window.<script>window.close()</script>'
            headers = ['http/1.1 200 ok',
                       "date: #{Time.now.httpdate}",
                       'server: ruby',
                       'content-type: text/html; charset=iso-8859-1',
                       "content-length: #{resp.length}\r\n\r\n"].join("\r\n")
            client.puts headers # send the time to the client
            client.puts resp
            client.close
            break
          end
        end

        timeout = Thread.new do
          sleep 30
          listen.kill
          puts
        end
        join = listen.join

        listen[:value]['code']
      end

      def get_token(code)
        uri = URI.parse(AUTH_TOKEN_URI)
        header = {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
        body = {
          'grant_type' => 'authorization_code',
          'client_id' => CLIENT_ID,
          'scope' => 'https://buildingsmartservices.onmicrosoft.com/api/read offline_access',
          'code' => code,
          'redirect_uri' => @redirect_uri,
          'code_verifier' => @state
        }

        # Create the HTTP objects
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri, header)
        request.body = URI.encode_www_form(body)

        # Send the request
        response = http.request(request)
        JSON.parse(response.body)['access_token']
      end
    end
  end
end
