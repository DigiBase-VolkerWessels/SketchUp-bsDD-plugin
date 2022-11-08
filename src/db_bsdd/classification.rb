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
    require File.join(PLUGIN_ZIP_PATH, 'zip.rb') unless defined? BimTools::Zip

    # bSDD domain to sketchup classification converter
    class Classification
      def initialize(domain_name, uri)
        @domain_name = domain_name
        @uri = uri
      end
      
      # Download bSDD domain as xsd
      #
      # @param file_path [String] file path
      # @param token [String] OAuth Access Token
      def download(file_path, domain_details, token)
        header = {
          'Content-Type': 'multipart/form-data', # 'application/x-www-form-urlencoded',#'application/json',#
          'Authorization': 'Bearer ' + token
        }
        body = {
          'DomainNamespaceUri' => @uri,
          'ExportFormat' => 'Sketchup'
          # 'UseNestedClassifications' => true
        }
        params = URI.encode_www_form(body)
        uri_full = URI.parse(Settings.bsdd_api['RequestExportFile'] + '?' + params)
        http = Net::HTTP.new(uri_full.host, uri_full.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri_full, header)
        response = http.request(request)
        write_skc(file_path, response.body, domain_details) if response.is_a?(Net::HTTPSuccess)
      end
      
      # Get domain details
      #
      # @param token [String] OAuth Access Token
      def domain_details(token)
        header = {
          'Content-Type': 'multipart/form-data', # 'application/x-www-form-urlencoded',#'application/json',#
          'Authorization': 'Bearer ' + token
        }
        body = {
          'namespaceUri' => @uri
        }
        params = URI.encode_www_form(body)
        uri_full = URI.parse(Settings.bsdd_api['domain'] + '?' + params)
        http = Net::HTTP.new(uri_full.host, uri_full.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri_full, header)
        response = http.request(request)
        return JSON.parse(response.body).first if response.is_a?(Net::HTTPSuccess)
      end
      
      # Create sketchup skc file from xsd
      #
      # @param file_path [String] file path
      # @param xsd [String] XSD data
      def write_skc(file_path, xsd, domain_details)
        domain_details.default = ""
        schema_path = File.join('Schemas', @domain_name + '.xsd')
        BimTools::Zip::OutputStream.open(file_path) do |zos|
          zos.put_next_entry(schema_path)
          zos.puts xsd

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
  <dp:title>#{domain_details['name']}</dp:title>
  <dp:description>Demo definitie</dp:description>
  <dp:creator>#{domain_details['organizationNameOwner']}</dp:creator>
  <dp:keywords></dp:keywords>
  <dp:lastModifiedBy></dp:lastModifiedBy>
  <dp:revision>#{domain_details['version']}</dp:revision>
  <dp:created>#{domain_details['releaseDate']}</dp:created>
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
      end

      # Check if classification is loaded, otherwise load it
      #
      # @param model [Sketchup::Model] Sketchup model to load classifications
      def load(model)
        classifications = model.classifications
        if classifications[@domain_name]
          log_info("Classification already loaded:\r\n'#{@domain_name}'")
        else
          file_path = File.join(PLUGIN_PATH_CLASSIFICATIONS, @domain_name + '.skc')
          if token = BSDD.authentication.token
            domain_details = domain_details(token)
            set_classifiction_details(domain_details)
            download(file_path, domain_details, token)
            if classifications.load_schema(file_path)
              log_info("Classification loaded from bSDD:\r\n'#{@domain_name}'")
            else
              log_info("Unable to load classification:\r\n'#{@domain_name}'")
            end
          end
        end
      end

      # Log info message
      #
      # @param message [SString] Log message
      def log_info(message)
        puts message
        UI::Notification.new(BSDD_EXTENSION, message).show
      end

      def set_classifiction_details(domain_details)
        su_model = Sketchup.active_model
        su_model.set_attribute('IfcManager', 'description', '')
        project_data = su_model.attribute_dictionaries['IfcManager']
        project_data.set_attribute('Classifications', 'description', '')
        classifications = project_data.attribute_dictionaries['Classifications']
        classifications.set_attribute(domain_details['name'], 'location', domain_details['namespaceUri'])
        classifications.set_attribute(domain_details['name'], 'source', domain_details['organizationNameOwner'])
        classifications.set_attribute(domain_details['name'], 'edition', domain_details['version'])
        classifications.set_attribute(domain_details['name'], 'editiondate', domain_details['releaseDate'])
      end
    end
  end
end
