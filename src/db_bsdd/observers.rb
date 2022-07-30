# frozen_string_literal: true

# observers.rb

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
 module BSDD
  module Observers
    attr_accessor :timestamp
    extend self

    def update()
      if(Time.now.to_f - Observers.timestamp) > 0.5
        Observers.timestamp = Time.now.to_f
      end
    end

    # observer that updates the window on selection change
    class IMSelectionObserver < Sketchup::SelectionObserver
      def onSelectionBulkChange(selection)
        puts 'onSelectionBulkChange'
        Observers.update
      end
      def onSelectionCleared(selection)
        puts 'onSelectionCleared'
      end
      def onSelectionAdded(selection,entity)
        puts 'onSelectionAdded'
      end
    end

    # observer that updates the window when selected entity changes
    class IMEntitiesObserver < Sketchup::EntitiesObserver
      def onElementModified(entities,entity)
        puts 'onElementModified'
        # if Sketchup.active_model.selection.include?(entity)
        #   Observers.timestamp = Time.now.to_f
        # end
      end
      def onElementAdded(entities,entity)
        puts 'onElementAdded'
        if entity.deleted? || Sketchup.active_model.selection.include?(entity)
          Observers.timestamp = Time.now.to_f
        end
      end
    end

    class IMAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        puts 'onNewModel'
        switch_model()
      end
      def onOpenModel(model)
        puts 'onOpenModel'
        switch_model()
      end

      # actions when switching/loading models
      def switch_model()

        Observers.timestamp = Time.now.to_f

        # when new model is loaded, close window (?) instantaneous re-open does not work?
        PropertiesWindow.close
        PropertiesWindow.create

        # also load classifications into new model
        Settings.load_classifications
      end
    end

    self.timestamp = 0
    Sketchup.add_observer(IMAppObserver.new)
    @sel_observer = IMSelectionObserver.new
    @ent_observer = IMEntitiesObserver.new
    @app_observer = IMAppObserver.new

    # Attach observers on menu open
    def start()
      Sketchup.active_model.selection.add_observer(@sel_observer)
      Sketchup.active_model.entities.add_observer(@ent_observer) # (?) always the active entities object?
      Sketchup.active_model.selection.add_observer(@app_observer)
    end # def start

    # Remove observers on menu close
    def stop()
      Sketchup.active_model.selection.remove_observer(@sel_observer)
      Sketchup.active_model.entities.remove_observer(@ent_observer) # (?) always the active entities object?
      Sketchup.active_model.selection.remove_observer(@app_observer)
    end # def stop
  end # module Observers
 end # module BSDD
end # module DigiBase
