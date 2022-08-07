# frozen_string_literal: true

# db_bsdd.rb

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

# Create an entry in the Extension list that loads a script called
# loader.rb.
require 'sketchup'
require 'extensions'

module DigiBase
  PLUGIN_ROOT_PATH = File.dirname(__FILE__) unless defined? PLUGIN_ROOT_PATH

  module BSDD
    unless file_loaded?(__FILE__)

      # Version and release information.
      VERSION = '2.0.0'

      if Sketchup.version_number > 1_700_000_000
        PLUGIN_PATH       = File.join(PLUGIN_ROOT_PATH, 'db_bsdd')
        PLUGIN_IMAGE_PATH = File.join(PLUGIN_PATH, 'images')

        BSDD_EXTENSION = SketchupExtension.new('DigiBase bSDD classification tool', File.join(PLUGIN_PATH, 'loader.rb'))
        BSDD_EXTENSION.version = VERSION
        BSDD_EXTENSION.description = 'Add classifications and properties from the BuildingSMART Data Dictionary to IFC objects.'
        BSDD_EXTENSION.creator = 'DigiBase'
        BSDD_EXTENSION.copyright = '2022'
        Sketchup.register_extension(BSDD_EXTENSION, true)
      else
        UI.messagebox 'You need at least SketchUp 2017 to use this extension.'
      end
    end
  end
end
