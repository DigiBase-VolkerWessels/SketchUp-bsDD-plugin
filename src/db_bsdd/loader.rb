# loader.rb

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

# Main loader for BsDD plugin

module DigiBase
  module BsDD
    attr_reader :toolbar
    extend self

    PLATFORM_IS_OSX     = ( Object::RUBY_PLATFORM =~ /darwin/i ) ? true : false
    PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX

    # set icon file type
    if PLATFORM_IS_WINDOWS
      ICON_TYPE = '.svg'
    else # OSX
      ICON_TYPE = '.pdf'
    end

    PLUGIN_PATH_HTML = File.join(PLUGIN_PATH, 'html')
    PLUGIN_PATH_IMAGE = File.join(PLUGIN_PATH, 'images')
    PLUGIN_PATH_CSS = File.join(PLUGIN_PATH, 'css')
    PLUGIN_PATH_LIB = File.join(PLUGIN_PATH, 'lib')
    PLUGIN_PATH_UI = File.join(PLUGIN_PATH, 'ui')
    PLUGIN_PATH_TOOLS = File.join(PLUGIN_PATH, 'tools')
    PLUGIN_PATH_CLASSIFICATIONS = File.join(PLUGIN_PATH, 'classifications')

    # Create BsDD toolbar
    @toolbar = UI::Toolbar.new "bsDD Classifier"

    # Add open window button
    require File.join(PLUGIN_PATH, 'window.rb')
    btn_bsDD_window = UI::Command.new('Toggle bsDD classification window') {
      PropertiesWindow.toggle
    }
    btn_bsDD_window.small_icon = File.join(PLUGIN_PATH_IMAGE, "bsDD" + ICON_TYPE)
    btn_bsDD_window.large_icon = File.join(PLUGIN_PATH_IMAGE, "bsDD" + ICON_TYPE)
    btn_bsDD_window.tooltip = "add bsDD classification"
    btn_bsDD_window.status_bar_text = "add bsDD classification"

    @toolbar.add_item btn_bsDD_window
    @toolbar.show

  end # module BsDD
end # module DigiBase
