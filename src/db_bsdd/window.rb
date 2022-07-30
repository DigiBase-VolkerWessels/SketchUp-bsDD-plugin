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
  require File.join(PLUGIN_PATH, 'observers.rb')
  require File.join(PLUGIN_PATH, 'classification.rb')
  require File.join(PLUGIN_PATH, 'settings.rb')

  module PropertiesWindow
    attr_reader :window, :ready
    extend self
    @window = false
    @visible = false
    @ready = false
    @form_elements = Array.new
    @window_options = {
      :dialog_title    => 'bSDD classification',
      :preferences_key => 'DigiBase-bSDD-PropertiesWindow',
      :width           => 400,
      :height          => 400,
      :resizable       => true
    }

    # Create Sketchup HtmlDialog window
    def create()
      @form_elements = Array.new
      @window = UI::HtmlDialog.new( @window_options )
      @window.set_on_closed {
        BSDD::Observers.stop
      }

      @window.add_action_callback("token") { |action_context|
        token = BSDD::authentication.token
        if token
          @window.execute_script("token='#{token}'")
        end
      }

      @window.add_action_callback("set_recursive_setting") { |action_context|
        classifications = Settings.classifications.select {|k,v| v == true}        
        js_command = "recursive_setting = " + DigiBase::BSDD::Settings.recursive.to_s + ";"
        @window.execute_script(js_command)
      }

      @window.add_action_callback("ready") { |action_context|
      }

      @window.add_action_callback("updateDomainNamespaceUris") { |action_context|
        classifications = Settings.classifications.select {|k,v| v == true}        
        js_command = "domainNamespaceUris = '" + classifications.keys.join("','") + "';"
        @window.execute_script(js_command)
      }

      @window.add_action_callback("save") { |action_context, form|
        model = Sketchup.active_model
        classifications = model.classifications
        CGI::parse(form).each_pair do |key, array_value|          
          if array_value[0] != ''
            value = array_value[0]            
            key_list = key.split('___')
            case key_list[0]
            when "material"
              material_name = value
              material = model.materials[material_name]
              unless material
                material = model.materials.add(material_name)
                material.color = 'DarkGray'
              end
  
              model.selection.each do |entity|
                entity.material = material
              end
            when "domain"
              domain_name = key_list[1].gsub(/[^0-9A-z.\- ]/, '') # remove non filename characters
              domain_name.gsub!(/ +/,' ') # remove multiple spaces
              classification_name = key_list[2]
              domain_namespace_uri = value
              # Check if classification is loaded, otherwise load it
              unless classifications[domain_name]
                file = File.join(PLUGIN_PATH_CLASSIFICATIONS, domain_name + ".skc")

                # If not in plugin lib folder then check support files
                unless file
                  file = Sketchup.find_support_file(classification + ".skc", "Classifications")
                end
                if File.file?(file) && classifications.load_schema(file)
                  classifications.load_schema(file) if !file.nil?
                  message = "Classification loaded:\r\n'#{domain_name}'"
                  puts message
                  notification = UI::Notification.new(BSDD_EXTENSION, message)
                  notification.show
                else
                  success = false
                  token = BSDD::authentication.token
                  if token
                    classification = DigiBase::BSDD::Classification.new(domain_name, domain_namespace_uri, token)
                    skc_path = classification.download
                    if File.file?(skc_path) && classifications.load_schema(skc_path)
                      classifications.load_schema(file) if !file.nil?
                      message = "Classification loaded:\r\n'#{domain_name}'"
                      puts message
                      success = true
                      notification = UI::Notification.new(BSDD_EXTENSION, message)
                      notification.show
                    end
                  end
                  unless success
                    message = "Unable to load classification:\r\n'#{domain_name}'"
                    puts message
                    notification = UI::Notification.new(BSDD_EXTENSION, message)
                    notification.show
                  end
                end
              end
            when "classification"
              domain_name = key_list[1].gsub(/[^0-9A-z.\- ]/, '') # remove non filename characters
              domain_name.gsub!(/ +/,' ') # remove multiple spaces
              classification_name = key_list[2]
              model.selection.each do |entity|
                entity.definition.add_classification(domain_name, classification_name)
              end
              
            when 'property'
              propertyset_name = key_list[1]
              property_name = key_list[2]
              data_type = key_list[3]
              case data_type
              when "Boolean"
                if value == "on" || value == "true"
                  value = true
                elsif value == "off" || value == "false"
                  value = false
                else
                  value = value.to_b
                end
                value_type = 'IfcBoolean'
                attribute_type = "boolean"
              when "Character"
                value_type = 'IfcLabel'
                attribute_type = "string"
              when "Integer"
                value = value.to_i
                value_type = 'IfcInteger'
                attribute_type = "long"
              when "Real"
                value = value.to_f
                if value < 0                  
                  value_type = 'IfcLengthMeasure'
                else
                  value_type = 'IfcPositiveLengthMeasure'
                end
                attribute_type = "double"
              when "String"
                value_type = 'IfcLabel'
                attribute_type = "string"
              when "Time"
                value_type = 'IfcLabel'
                attribute_type = "string"
              else
                value_type = 'IfcLabel'
                attribute_type = "string"
              end
              model.selection.each do |entity|
                if entity.class.method_defined?(:definition)
                  definition = entity.definition              
                  ifc_dict = definition.attribute_dictionary("IFC 2x3")
                  if ifc_dict
                    pset_dict = ifc_dict.attribute_dictionary(propertyset_name, true)
                    property_dict = pset_dict.attribute_dictionary(property_name, true)
                    pset_dict.set_attribute property_name, "is_hidden", false
                    value_dict = property_dict.attribute_dictionary(value_type, true)
                    property_dict.set_attribute value_type, "attribute_type", attribute_type
                    property_dict.set_attribute value_type, "is_hidden", false
                    property_dict.set_attribute value_type, "value", value
                  end
                end
              end
            end
          end
        end
      }

      @window.add_action_callback("set_classification") { |action_context, classification, domain, properties, relations=[], namespaceUri|
        model = Sketchup.active_model
        classifications = model.classifications
        
        # Map mismatch in naming between SketchUp and bsDD classification
        if domain == "IFC"
          domain = "IFC 2x3"
        elsif domain == "NL-SfB 2005"
          domain = "NL-SfB tabel 1"
        elsif domain == "VolkerWessels Bouw & vastgoed"
          domain = "VolkerWessels Bouw en vastgoed"
        end

        # Check if classification is loaded, otherwise load it
        unless classifications[domain]
          file = File.join(PLUGIN_PATH_CLASSIFICATIONS, domain + ".skc")

          # If not in plugin lib folder then check support files
          unless file
            file = Sketchup.find_support_file(classification + ".skc", "Classifications")
          end
          if File.file?(file) && classifications.load_schema(file)
            classifications.load_schema(file) if !file.nil?
            message = "Classification loaded:\r\n'#{domain}'"
            puts message
          else
            
            token = BSDD::authentication.token
            if token
              classification = DigiBase::BSDD::Classification.new(namespaceUri, token)
              classification.download
            end

            message = "Unable to load classification:\r\n'#{domain}'"
            puts message
            notification = UI::Notification.new(BSDD_EXTENSION, message)
            notification.show
          end
        end
        
        # Add material
        if relations.is_a? Array
          relations.each do |relation|
            if relation.key?("relationType") && relation["relationType"]=="HasMaterial" && relation.key?("relatedClassificationName")
              model = Sketchup.active_model
              material_name = relation["relatedClassificationName"]
              material = model.materials[material_name]
              unless material
                material = model.materials.add(material_name)
                material.color = 'DarkGray'
              end

              Sketchup.active_model.selection.each do |entity|
                entity.material = material
              end
            end
          end
        end


        if model.classifications[domain]
          model.selection.each do |ent|
            if (ent.is_a? Sketchup::ComponentInstance) || (ent.is_a? Sketchup::Group)
              definition = ent.definition
              definition.add_classification(domain, classification)


              # Store properties
              if properties.is_a? Array
                properties.each do |property|
                  name = property["name"]
                  propertySet = property["propertySet"]
                  predefinedValue = property["PredefinedValue"]
                  if predefinedValue == "TRUE" || predefinedValue == "FALSE"
                    if predefinedValue == "TRUE"
                      predefinedValue = true
                    else
                      predefinedValue = false
                    end

                    propertyDomainName = property["propertyDomainName"]
                    if propertyDomainName == "IFC"

                      # Set IFC classification
                      ifc_dict = definition.attribute_dictionary("IFC 2x3", create = true)
                      propertySet_dict = ifc_dict.attribute_dictionary(propertySet, create = true)
                      propertySet_dict.set_attribute(name, "attribute_type", "boolean")
                      propertySet_dict.set_attribute(name, "is_hidden", false)
                      propertySet_dict.set_attribute(name, "value", predefinedValue)
                    end
                  end
                end
              end
            end
          end
        end
      }
    end # def create

    # def update_search_list()
    #   search_list = Hash.new
    #   if @guid != ""
    #     result = BSDD.get_SearchListOpen(domain_guid=@guid, search_text="", language_code=@language_value, related_ifc_entity=@ifcFilter.value)
    #     if result["domains"]
    #       result["domains"].each do |domain|
    #         if domain["classifications"]
    #           domain["classifications"].each do |search_results|
    #             search_list[search_results["namespaceUri"]] = search_results["name"]
    #           end
    #         end
    #       end
    #     end
    #   end
    #   @search.options = search_list
    #   @search.set_options()
    #   @search.value = "-"
    # end # def update_search_list

    def close
      BSDD::Observers.stop
      if @window
        @window.close
      end
    end # def close

    # show Sketchup HtmlDialog window
    def show
      BSDD::Observers.start
      self.create()
      self.set_html
      unless @window.visible?
        @window.show
      end
    end # def show

    def toggle
      if @window
        if@window.visible?
          self.close
        else
          self.show
        end
      else
        self.create()
        self.show
      end
    end # def toggle

    def set_html()
      model = Sketchup.active_model
      ifc_able = false
      model.selection.each do |ent|
        if(ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group))
          ifc_able = true
          break
        end
      end
      @window.set_url(File.join(PLUGIN_PATH_HTML, 'index.html'))
    end # def set_html
  end # module PropertiesWindow
 end # module BSDD
end # module DigiBase
