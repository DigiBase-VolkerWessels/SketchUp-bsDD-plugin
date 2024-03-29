# frozen_string_literal: true

# settings.rb

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

require 'json'
require 'yaml'
require 'json'

module DigiBase
  module BSDD
    require File.join(PLUGIN_PATH, 'settings.rb')
    module Settings
      extend self

      attr_reader :window, :ready, :classifications, :recursive, :ifc_version, :ignored_domains, :test_environment,
                  :bsdd_api

      @window = false
      @ready = false
      @recursive = false
      @default_ifc_version = 'IFC 2x3'
      @ifc_version = @default_ifc_version
      @ifc_versions = ['IFC 2x3', 'IFC 4']
      @ignored_domains = ['ifc-4.3']
      @test_environment = false
      @bsdd_api = {}
      @settings_file = File.join(PLUGIN_PATH, 'settings.yml')
      @classifications = {}
      @window_options = {
        dialog_title: 'bSDD settings',
        preferences_key: 'DigiBase-bSDD-Settings',
        width: 400,
        height: 400,
        resizable: true
      }

      def set_ifc_version
        classifications = Sketchup.active_model.classifications
        @active_ifc_versions = classifications.keys.intersection(@ifc_versions)
        if @active_ifc_versions.count == 0
          unless classifications[@default_ifc_version]
            file = Sketchup.find_support_file('IFC 2x3.skc', 'Classifications')
            classifications.load_schema(file) unless file.nil?
          end
          @active_ifc_versions = [@default_ifc_version]
        end
        @ifc_version = @active_ifc_versions.first unless @active_ifc_versions.include? @ifc_version
      rescue StandardError
        message = 'Unable to set IFC version'
        puts message
        notification = UI::Notification.new(BSDD_EXTENSION, message)
        notification.show
      end

      def load
        if settings = YAML.safe_load(File.read(@settings_file))
          @classifications = settings['classifications'] if settings.key?('classifications')
          @ifc_version = settings['ifc_version'] if settings.key?('ifc_version')
          @ignored_domains = settings['ignored_domains'] if settings.key?('ignored_domains')
          @test_environment = settings['test_environment'] if settings.key?('test_environment')
          @active_ifc_versions = if settings.key?('ifc_versions')
                                   settings['ifc_versions']
                                 else
                                   @ifc_versions
                                 end
          @bsdd_environment = settings['bsdd_environment']
          @bsdd_endpoint = settings['bsdd_endpoint']
          @recursive = settings['recursive'] if settings.key?('recursive')
        end
        set_bsdd_api
        set_ifc_version
      rescue StandardError
        message = "Default settings loaded.\r\nUnable to load settings from:\r\n'#{@settings_file}'"
        puts message
        notification = UI::Notification.new(BSDD_EXTENSION, message)
        notification.show
      end

      # Create Sketchup HtmlDialog window
      def create
        @window = UI::HtmlDialog.new(@window_options)
        @window.add_action_callback('ready') do |_action_context|
          js_command = "$('#test_environment').prop('checked', #{@test_environment});"
          @window.execute_script(js_command)

          js_command = "$('#recursive').prop('checked', #{@recursive});"
          @window.execute_script(js_command)

          js_command = "updateIfcVersions('#{@active_ifc_versions.to_json}');"
          @window.execute_script(js_command)

          js_command = "$('#ifcVersion').val('#{@ifc_version}');"
          @window.execute_script(js_command)

          @classifications.each_pair do |classification, status|
            if status
              js_command = "$('#' + '#{classification}'.replace(/[^a-zA-Z0-9]/g, '')).prop('checked',true);"
              @window.execute_script(js_command)
            end
          end
        end

        # Save settings
        @window.add_action_callback('save') do |_action_context, form_data|
          settings = JSON.parse(form_data)
          @classifications = settings['classifications']
          @recursive = settings['recursive']
          @test_environment = settings['test_environment']
          ifc_versions = @ifc_versions.union(@active_ifc_versions)
          @ifc_version = settings['ifcVersion']
          File.open(@settings_file, 'w') do |f|
            f.write({
              'classifications' => @classifications,
              'ifc_version' => @ifc_version,
              'ifc_versions' => ifc_versions,
              'ignored_domains' => @ignored_domains,
              'test_environment' => @test_environment,
              'recursive' => @recursive,
              'bsdd_environment' => @bsdd_environment,
              'bsdd_endpoint' => @bsdd_endpoint
            }.to_yaml)
          end
          close
          DigiBase::BSDD::PropertiesWindow.close
          load
        end
      end

      def close
        @window.close if @window
      end

      def show
        load
        create
        set_html
        @window.show unless @window.visible?
      end

      def toggle
        if @window
          if @window.visible?
            close
          else
            show
          end
        else
          create
          show
        end
      end

      def set_html
        @window.set_file(File.join(PLUGIN_PATH_HTML, 'settings.html'))
      end

      def set_bsdd_api
        environment_name = if @test_environment
                             'test'
                           else
                             'production'
                           end
        environment_url = @bsdd_environment[environment_name]
        @bsdd_api = @bsdd_endpoint.map { |k, v| [k, environment_url + v] }.to_h
      end
    end
  end
end
