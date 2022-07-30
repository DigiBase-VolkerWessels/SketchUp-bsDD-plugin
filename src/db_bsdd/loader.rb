# frozen_string_literal: true

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

# Main loader for bSDD plugin

module DigiBase
  module BSDD
    attr_reader :toolbar, :authentication

    extend self

    PLATFORM_IS_OSX     = Object::RUBY_PLATFORM =~ /darwin/i ? true : false
    PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX

    # set icon file type
    if Sketchup.version_number < 1_600_000_000
      ICON_TYPE = '.png'
      ICON_SMALL = '_small'
      ICON_LARGE = '_large'
    elsif PLATFORM_IS_WINDOWS
      ICON_TYPE = '.svg'
      ICON_SMALL = ''
      ICON_LARGE = ''
    else # OSX
      ICON_TYPE = '.pdf'
      ICON_SMALL = ''
      ICON_LARGE = ''
    end

    PLUGIN_PATH_HTML = File.join(PLUGIN_PATH, 'html')
    PLUGIN_PATH_IMAGE = File.join(PLUGIN_PATH, 'images')
    PLUGIN_PATH_CSS = File.join(PLUGIN_PATH, 'css')
    PLUGIN_PATH_LIB = File.join(PLUGIN_PATH, 'lib')
    PLUGIN_PATH_UI = File.join(PLUGIN_PATH, 'ui')
    PLUGIN_PATH_TOOLS = File.join(PLUGIN_PATH, 'tools')
    PLUGIN_PATH_CLASSIFICATIONS = File.join(PLUGIN_PATH, 'classifications')

    # Set the path to the correct Rubyzip version for this Ruby version
    PLUGIN_ZIP_PATH = if RUBY_VERSION.split('.')[1].to_i < 4
                        File.join(PLUGIN_PATH, 'lib', 'rubyzip-1.3.0')
                      else
                        File.join(PLUGIN_PATH, 'lib', 'rubyzip-2.3.2')
                      end

    require File.join(PLUGIN_PATH, 'auth.rb')
    require File.join(PLUGIN_PATH, 'window.rb')

    # Create bSDD toolbar
    @toolbar = UI::Toolbar.new 'bSDD Classifier'

    # Load settings from yaml file
    require File.join(PLUGIN_PATH, 'settings.rb')
    Settings.load()

    # Create authenticator
    @authentication = Authentication.new

    # Add open window button
    btn_bsdd_window = UI::Command.new('Toggle bSDD classification window') do
      PropertiesWindow.toggle
    end
    btn_bsdd_window.small_icon = File.join(PLUGIN_PATH_IMAGE, 'bsdd' + ICON_TYPE)
    btn_bsdd_window.large_icon = File.join(PLUGIN_PATH_IMAGE, 'bsdd' + ICON_TYPE)
    btn_bsdd_window.tooltip = 'search bSDD'
    btn_bsdd_window.status_bar_text = 'search bSDD and classify objects'

    # Open settings window
    btn_settings_window = UI::Command.new('bSDD Classifier settings') do
      Settings.toggle
    end
    btn_settings_window.small_icon = File.join(PLUGIN_PATH_IMAGE, "Settings#{ICON_SMALL}#{ICON_TYPE}")
    btn_settings_window.large_icon = File.join(PLUGIN_PATH_IMAGE, "Settings#{ICON_LARGE}#{ICON_TYPE}")
    btn_settings_window.tooltip = 'Open bSDD Classifier settings'
    btn_settings_window.status_bar_text = 'Open bSDD Classifier settings'

    @toolbar.add_item btn_settings_window
    @toolbar.add_item btn_bsdd_window
    @toolbar.show
  end # module BSDD
end # module DigiBase
