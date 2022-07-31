# frozen_string_literal: true

# classification.rb

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

module DigiBase
  module BSDD
    require File.join(PLUGIN_ZIP_PATH, 'zip.rb')
    class Classification
      BASE_URL = "https://test.bsdd.buildingsmart.org/"
      ENDPOINT = BASE_URL + "api/RequestExportFile/preview"
      def initialize(domain_name, uri, token)
        @domain_name = domain_name
        @uri = uri
        @token = token
      end
      def download()
        uri = URI.parse(ENDPOINT)
        header = {
          'Content-Type': 'multipart/form-data',#'application/x-www-form-urlencoded',#'application/json',# 
          'Authorization': "Bearer " + @token
        }
        body = {
          'DomainNamespaceUri' => @uri,
          'ExportFormat' => 'Sketchup'#,
          #'UseNestedClassifications' => true
        }
        params = URI.encode_www_form(body)
        uri_full = URI.parse(ENDPOINT + '?' + params)

        # puts body
        # Create the HTTP objects
        http = Net::HTTP.new(uri_full.host, uri_full.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri_full, header)
        # request.body = body.to_json#URI.encode_www_form(body)#

        # Send the request
        response = http.request(request)
        # return JSON.parse(response.body)['access_token']



        if response.is_a?(Net::HTTPSuccess)
          schema_path = File.join('Schemas',@domain_name)
          skc_path = File.join(PLUGIN_PATH_CLASSIFICATIONS, @domain_name + '.skc')

          BimTools::Zip::OutputStream.open(skc_path) do |zos|
            zos.put_next_entry(schema_path)
            zos.puts response.body
          
            zos.put_next_entry('document.xml')
            zos.puts <<-DOC
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<classificationDocument xmlns="http://www.sketchup.com/schemas/sketchup/1.0/classification" xmlns:r="http://www.sketchup.com/schemas/1.0/references" xmlns:cls="http://www.sketchup.com/schemas/sketchup/1.0/classification" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sketchup.com/schemas/sketchup/1.0/classification http://www.sketchup.com/schemas/sketchup/1.0/classification.xsd">
  <cls:Classification xsdFile="#{schema_path}"></cls:Classification>
</classificationDocument>
DOC

            zos.put_next_entry('documentProperties.xml')
            zos.puts <<-DOC
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<documentProperties xmlns="http://www.sketchup.com/schemas/1.0/documentproperties" xmlns:dp="http://www.sketchup.com/schemas/1.0/documentproperties" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sketchup.com/schemas/1.0/documentproperties http://www.sketchup.com/schemas/1.0/documentproperties.xsd">
  <dp:title>#{@domain_name}</dp:title>
  <dp:description>Demo definitie</dp:description>
  <dp:creator></dp:creator>
  <dp:keywords></dp:keywords>
  <dp:lastModifiedBy></dp:lastModifiedBy>
  <dp:revision>1</dp:revision>
  <dp:created>2022-02-03T14:28:00</dp:created>
  <dp:modified>2022-02-03T14:28:00</dp:modified>
  <dp:thumbnail></dp:thumbnail>
  <dp:generator dp:name="Classification" dp:version="1"/>
</documentProperties>
DOC

            zos.put_next_entry('references.xml')
            zos.puts <<-DOC
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<references xmlns="http://www.sketchup.com/schemas/1.0/references" xmlns:r="http://www.sketchup.com/schemas/1.0/references" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sketchup.com/schemas/1.0/references http://www.sketchup.com/schemas/1.0/references.xsd"/>
DOC

          end
          return skc_path

        end
        return false

      end
    end
  end
end