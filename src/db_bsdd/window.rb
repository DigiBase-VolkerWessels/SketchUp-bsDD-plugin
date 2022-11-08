# frozen_string_literal: true

# window.rb

# Copyright (c) 2020 DigiBase B.V.

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

require 'cgi'

module DigiBase
  module BSDD
    require File.join(PLUGIN_PATH, 'classification.rb')
    require File.join(PLUGIN_PATH, 'settings.rb')

    module PropertiesWindow
      attr_reader :window, :ready

      extend self
      @window = false
      @visible = false
      @ready = false
      @form_elements = []
      @window_options = {
        dialog_title: 'bSDD classification',
        preferences_key: 'DigiBase-bSDD-PropertiesWindow',
        width: 400,
        height: 400,
        resizable: true
      }

      # Create Sketchup HtmlDialog window
      def create
        @form_elements = []
        @window = UI::HtmlDialog.new(@window_options)

        @window.add_action_callback('token') do |_action_context|
          token = BSDD.authentication.token
          @window.execute_script("token='#{token}'") if token
        end

        @window.add_action_callback('set_environment') do |_action_context|
          environment = if DigiBase::BSDD::Settings.test_environment
                          'test'
                        else
                          'production'
                        end
          js_command = "environment = '" + environment + "';"
          @window.execute_script(js_command)
        end

        @window.add_action_callback('set_recursive_setting') do |_action_context|
          classifications = Settings.classifications.select { |_k, v| v == true }
          js_command = "recursive_setting = #{DigiBase::BSDD::Settings.recursive};"
          @window.execute_script(js_command)
        end

        @window.add_action_callback('ready') do |action_context|
        end

        @window.add_action_callback('updateDomainNamespaceUris') do |_action_context|
          classifications = Settings.classifications.select { |_k, v| v == true }
          js_command = "domainNamespaceUris = '#{classifications.keys.join("','")}';"
          @window.execute_script(js_command)
        end

        @window.add_action_callback('save') do |_action_context, form|
          description = false
          model = Sketchup.active_model
          CGI.parse(form).each_pair do |key, array_value|
            next unless array_value[0] != ''

            value = array_value[0]
            key_list = key.split('___')
            case key_list[0]
            when 'ifcType'
              unless value.empty?
                model.selection.each do |entity|
                  entity.definition.add_classification(BSDD::Settings.ifc_version, value)
                end
              end
            when 'name'
              unless value.empty?
                model.selection.each do |entity|
                  entity.name = value if defined?(entity.name)
                end
              end
            when 'material'
              material_name = value
              material = model.materials[material_name]
              unless material
                material = model.materials.add(material_name)
                material.color = 'DarkGray'
              end

              model.selection.each do |entity|
                entity.material = material
              end
            when 'domain'
              domain_name = key_list[1].gsub(/[^0-9A-z.\- ]/, '') # remove non filename characters
              domain_name.gsub!(/ +/, ' ') # remove multiple spaces

              # Don't use bSDD version of IFC
              unless BSDD::Settings.ignored_domains.include? domain_name
                classification_name = key_list[2]
                domain_namespace_uri = value
                classification = DigiBase::BSDD::Classification.new(domain_name, domain_namespace_uri)
                classification.load(model)
              end
            when 'classification'
              domain_name = key_list[1].gsub(/[^0-9A-z.\- ]/, '') # remove non filename characters
              domain_name.gsub!(/ +/, ' ') # remove multiple spaces
              classification_name = key_list[2]

              # Don't use bSDD version of IFC
              unless BSDD::Settings.ignored_domains.include? domain_name
                model.selection.each do |entity|
                  entity.definition.add_classification(domain_name, classification_name)
                end
              end
              
              # Set IfcDescription
              unless description
                description = true
                set_attribute(model, "Description", "IfcText", "string", classification_name)
              end
            when 'property'
              propertyset_name = key_list[1]
              property_name = key_list[2]
              data_type = key_list[3]
              case data_type
              when 'Boolean'
                value = if %w[on true].include?(value)
                          true
                        elsif %w[off false].include?(value)
                          false
                        else
                          value.to_b
                        end
                value_type = 'IfcBoolean'
                attribute_type = 'boolean'
              when 'Character'
                value_type = 'IfcLabel'
                attribute_type = 'string'
              when 'Integer'
                value = value.to_i
                value_type = 'IfcInteger'
                attribute_type = 'long'
              when 'Real'
                value = value.to_f
                value_type = if value < 0
                               'IfcLengthMeasure'
                             else
                               'IfcPositiveLengthMeasure'
                             end
                attribute_type = 'double'
              when 'String'
                value_type = 'IfcLabel'
                attribute_type = 'string'
              when 'Time'
                value_type = 'IfcLabel'
                attribute_type = 'string'
              else
                value_type = 'IfcLabel'
                attribute_type = 'string'
              end
              set_property(model, propertyset_name, property_name, value_type, attribute_type, value)
            end
          end
        end

        def set_property(model, propertyset_name, property_name, value_type, attribute_type, value)
          model.selection.each do |entity|
            next unless entity.class.method_defined?(:definition)

            definition = entity.definition
            ifc_dict = definition.attribute_dictionary(BSDD::Settings.ifc_version)
            next unless ifc_dict

            pset_dict = ifc_dict.attribute_dictionary(propertyset_name, true)
            property_dict = pset_dict.attribute_dictionary(property_name, true)
            pset_dict.set_attribute property_name, 'is_hidden', false
            value_dict = property_dict.attribute_dictionary(value_type, true)
            property_dict.set_attribute value_type, 'attribute_type', attribute_type
            property_dict.set_attribute value_type, 'is_hidden', false
            property_dict.set_attribute value_type, 'value', value
          end
        end

        def set_attribute(model, property_name, value_type, attribute_type, value)
          model.selection.each do |entity|
            next unless entity.class.method_defined?(:definition)

            definition = entity.definition
            ifc_dict = definition.attribute_dictionary(BSDD::Settings.ifc_version)
            next unless ifc_dict

            property_dict = ifc_dict.attribute_dictionary(property_name)
            next unless property_dict

            value_dict = property_dict.attribute_dictionary(value_type, true)
            property_dict.set_attribute value_type, 'attribute_type', attribute_type
            property_dict.set_attribute value_type, 'value', value
          end
        end
      end

      def close
        @window.close if @window
      end

      # show Sketchup HtmlDialog window
      def show
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
        model = Sketchup.active_model
        ifc_able = false
        model.selection.each do |ent|
          if ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group)
            ifc_able = true
            break
          end
        end
        @window.set_file(File.join(PLUGIN_PATH_HTML, 'index.html'))
      end
    end
  end
end
