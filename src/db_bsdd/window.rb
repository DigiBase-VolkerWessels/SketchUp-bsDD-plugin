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

module DigiBase
 module BsDD
  require File.join(PLUGIN_PATH, 'observers.rb')

  module PropertiesWindow
    attr_reader :window, :ready
    extend self
    @window = false
    @visible = false
    @ready = false
    @form_elements = Array.new
    @window_options = {
      :dialog_title    => 'bsDD classification',
      :preferences_key => 'DigiBase-BsDD-PropertiesWindow',
      :width           => 400,
      :height          => 400,
      :resizable       => true
    }

    # Create Sketchup HtmlDialog window
    def create()
      @form_elements = Array.new
      @window = UI::HtmlDialog.new( @window_options )
      @window.set_on_closed {
        BsDD::Observers.stop
      }

      @window.add_action_callback("update") { |action_context|
        update_selected_ifc_type()
      }

      @window.add_action_callback("set_classification") { |action_context, classification, domain, properties|
        model = Sketchup.active_model
        classifications = model.classifications

        # Map mismatch in naming between SketchUp and bsDD classification
        if domain == "IFC"
          domain = "IFC 2x3"
        elsif domain == "NL-SfB 2005"
          domain = "NL-SfB 2005, tabel 1"
        end

        # Check if classification is loaded, otherwise load it
        unless classifications[domain]
          file = File.join(PLUGIN_PATH_CLASSIFICATIONS, domain + ".skc")

          # If not in plugin lib folder then check support files
          unless file
            file = Sketchup.find_support_file(classification + ".skc", "Classifications")
          end
          if File.file?(file)
            classifications.load_schema(file) if !file.nil?
            message = "Classification loaded:\r\n'#{domain}'"
            puts message
          else
            message = "Unable to load classification:\r\n'#{domain}'"
            puts message
            notification = UI::Notification.new(BsDD_EXTENSION, message)
            notification.show
          end
        end

        if model.classifications[domain]
          model.selection.each do |ent|
            if (ent.is_a? Sketchup::ComponentInstance) || (ent.is_a? Sketchup::Group)
              definition = ent.definition
              definition.add_classification(domain, classification)

              # Store properties
              properties.each do |property|
                name = property["name"]
                propertySet = property["propertySet"]
                predefinedValue = property["predefinedValue"]
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
      }
    end # def create

    # Update related IFC type in window based on selection
    # If multiple IFC types are selected value will be '...'
    def update_selected_ifc_type()
      model = Sketchup.active_model
      ifc_type_value = nil
      model.selection.each do |ent|
        ifc_type = ent.definition.get_attribute("AppliedSchemaTypes", "IFC 2x3")

        # workaround for deprecated IfcWallStandardcase
        if ifc_type == "IfcWallStandardCase"
          ifc_type = "IfcWall"
        end
        if ifc_type
          if ifc_type_value
            if ifc_type != ifc_type_value
              ifc_type_value = "..."
              break
            end
          else
            if ifc_type
              ifc_type_value = ifc_type
            end
          end
          js = "setIfcValue('#{ifc_type_value}');"
          @window.execute_script(js)
        end
      end
    end

    def update_search_list()
      search_list = Hash.new
      if @guid != ""
        result = BsDD.get_SearchListOpen(domain_guid=@guid, search_text="", language_code=@language_value, related_ifc_entity=@ifcFilter.value)
        if result["domains"]
          result["domains"].each do |domain|
            if domain["classifications"]
              domain["classifications"].each do |search_results|
                search_list[search_results["namespaceUri"]] = search_results["name"]
              end
            end
          end
        end
      end
      @search.options = search_list
      @search.set_options()
      @search.value = "-"
    end # def update_search_list

    def close
      BsDD::Observers.stop
      if @window
        @window.close
      end
    end # def close

    # show Sketchup HtmlDialog window
    def show
      BsDD::Observers.start
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
        puts ent
        if(ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group))
          ifc_able = true
          break
        end
      end
      if(ifc_able)
        @window.set_url(File.join(PLUGIN_PATH_HTML, 'index.html'))
        update_selected_ifc_type()
      else
        @window.set_url(File.join(PLUGIN_PATH_HTML, 'empty.html'))
      end
    end # def set_html
  end # module PropertiesWindow
 end # module BsDD
end # module DigiBase
