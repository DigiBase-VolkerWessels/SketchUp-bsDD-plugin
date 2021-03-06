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
require 'sketchup.rb'
require 'extensions.rb'

module DigiBase
  PLUGIN_ROOT_PATH = File.dirname(__FILE__) unless defined? PLUGIN_ROOT_PATH

  module BsDD
    unless file_loaded?(__FILE__)

      # Version and release information.
      VERSION = '1.0.1'.freeze

      # load plugin only if SketchUp version is PRO
      if Sketchup.is_pro? && Sketchup.version_number>1600000000
        PLUGIN_PATH       = File.join(PLUGIN_ROOT_PATH, 'db_bsdd')
        PLUGIN_IMAGE_PATH = File.join(PLUGIN_PATH, 'images')

        BsDD_EXTENSION = SketchupExtension.new("DigiBase bsDD classification tool", File.join(PLUGIN_PATH, 'loader.rb'))
        BsDD_EXTENSION.version = VERSION
        BsDD_EXTENSION.description = 'Add classifications and properties from the BuildingSMART Data Dictionary to IFC objects.'
        BsDD_EXTENSION.creator = 'DigiBase'
        BsDD_EXTENSION.copyright = '2020'
        Sketchup.register_extension(BsDD_EXTENSION, true)
      else
        UI.messagebox "You need at least SketchUp Pro 2016 to use this extension."
      end
    end
  end # module BsDD
end # module DigiBase
