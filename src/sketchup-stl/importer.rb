# jf_stl_importer.rb - Imports ascii and binary .stl file in SketchUp
#
# Copyright (C) 2010 Jim Foltz (jim.foltz@gmail.com)
#
# License: Apache License, Version 2.0

require 'sketchup'

module CommunityExtensions
  module STL
    class Importer < Sketchup::Importer

      Sketchup::require File.join(PLUGIN_PATH, 'webdialog_extensions')

      include CommunityExtensions::STL::Utils

      PREF_KEY = 'CommunityExtensions\STL\Importer'.freeze

      IMPORT_SUCCESS                        = ImportSuccess
      IMPORT_FAILED                         = ImportFail
      IMPORT_CANCELLED                      = ImportCanceled
      IMPORT_FILE_NOT_FOUND                 = ImportFileNotFound
      IMPORT_SKETCHUP_VERSION_NOT_SUPPORTED = 5

      def initialize
        @stl_units = UNIT_MILLIMETERS
        @stl_merge = false
        @stl_preserve_origin = true
        @option_window = nil # (See comment at top of `stl_dialog()`.)
      end

      def description
        'STereo Lithography Files (*.stl)'
      end

      def id
        'com.sketchup.sketchup-stl'
      end

      def file_extension
        'stl'
      end

      def supports_options?
        true
      end

      def do_options
        stl_dialog
      end

      def load_file(path,status)
        begin
          status = main(path)
        rescue Exception => e
          puts e.message
          puts e.backtrace.join("\n")
          status = IMPORT_FAILED
        end
        return status
      end

      def main(filename)
        file_type = detect_file_type(filename)
        #p file_type
        # Read import settings.
        @stl_merge           = read_setting('merge_faces',     @stl_merge)
        @stl_units           = read_setting('import_units',    @stl_units)
        @stl_preserve_origin = read_setting('preserve_origin', @stl_preserve_origin)
        # Wrap everything into one operation, ensuring compatibility with older
        # SketchUp versions that did not feature the disable_ui argument.
        model = Sketchup.active_model
        if model.method(:start_operation).arity == 1
          model.start_operation(STL.translate('STL Import'))
        else
          model.start_operation(STL.translate('STL Import'), true)
        end
        # Import geometry.
        Sketchup.status_text = STL.translate('Importing geometry...')
        if file_type[/solid/]
          entities = stl_ascii_import(filename)
        else
          entities = stl_binary_import(filename)
        end
        return IMPORT_CANCELLED if entities == IMPORT_CANCELLED
        # Verify that anything was imported.
        if entities.nil? || entities.length == 0
          model.abort_operation
          UI.messagebox(STL.translate('No geometry was imported.')) if entities
          Sketchup.status_text = '' # OSX doesn't reset the statusbar like Windows.
          return IMPORT_FAILED
        end
        # Reposition to ORIGIN.
        container = entities.parent
        unless @stl_preserve_origin
          if container == model
            point = model.bounds.corner(0)
            vector = point.vector_to(ORIGIN)
            entities.transform_entities(vector, entities.to_a)
            model.active_view.zoom(entities.to_a)
          else
            group = container.instances[0]
            point = group.bounds.corner(0)
            vector = point.vector_to(ORIGIN)
            group.transform!(vector) if vector.valid?
            model.active_view.zoom([group])
          end
        end
        # Check if the imported geometry is a solid. If not, attempt to
        # automatically repair it.
        unless is_solid?(container.entities)
          Sketchup.status_text = STL.translate('Repairing geometry...')
          heal_geometry(container.entities)
        end
        # Clean up geometry.
        if @stl_merge
          Sketchup.status_text = STL.translate('Cleaning up geometry...')
          cleanup_geometry(entities)
        end
        Sketchup.status_text = STL.translate('Importing STL done!')
        model.commit_operation
        return IMPORT_SUCCESS
      end
      private :main

      def detect_file_type(file)
        first_line = File.open(file, 'r') { |f| f.read(80) }
        return first_line
      end
      private :detect_file_type

      def do_msg(msg)
        return UI.messagebox(msg, MB_YESNO)
      end
      private :do_msg

      def stl_binary_import(filename, try = 1)
        stl_conv = get_unit_ratio(@stl_units)
        f = File.new(filename, 'rb')
        # Header
        header = ''
        80.times {
          c = f.read(1).unpack('c')[0]
          if c <= 32 or c > 126 or c.nil?
            c = ?.
          end
          header << c
        }
        int_size = [42].pack('i').size
        float_size = [42.0].pack('f').size
        len = f.read(int_size).unpack('i')[0]

        pts = []
        while !f.eof 
          normal = f.read(3 * float_size).unpack('fff')
          v1 = f.read(3 * float_size).unpack('fff') 
          v1.map!{|e| e * stl_conv}
          v2 = f.read(3 * float_size).unpack('fff')
          v2.map!{|e| e * stl_conv}
          v3 = f.read(3 * float_size).unpack('fff')
          v3.map!{|e| e * stl_conv}
          # UINT16 Attribute byte count? (STL format spec)
          abc = f.read(2)
          pts << [v1, v2, v3]
        end # while
        f.close

        n_triangles = pts.length
        mesh = Geom::PolygonMesh.new(3 * n_triangles, n_triangles)
        pts.each { |poly| mesh.add_polygon(poly) }

        # add faces
        entities = Sketchup.active_model.entities
        if entities.length > 0
          grp = entities.add_group
          entities = grp.entities
        end
        st = entities.fill_from_mesh(mesh, false, 0)
        return entities
      end
      private :stl_binary_import

      def stl_ascii_import(filename, try = 1)
        stl_conv = get_unit_ratio(@stl_units)
        polys = []
        poly = []
        vcnt = 0
        IO.foreach(filename) do |line|
          line.chomp!
          if line[/vertex/]
            vcnt += 1
            c, *pts = line.split
            pts.map! { |pt| pt.to_f * stl_conv }
            poly << pts
            if vcnt == 3
              polys.push(poly.dup)# if vcnt > 0
              poly = []
              vcnt = 0
            end
          end
        end #loop
        if polys.length == 0
          if try == 1
            return stl_binary_import(filename, 2)
          end
        end
        mesh = Geom::PolygonMesh.new(3 * polys.length, polys.length)
        polys.each{ |poly| mesh.add_polygon(poly) }
        entities = Sketchup.active_model.entities
        if entities.length > 0
          grp = entities.add_group
          entities = grp.entities
        end
        st = entities.fill_from_mesh(mesh, false, 0)
        return entities
      end

      # Returns conversion ratio based on unit type.
      def get_unit_ratio(unit_type)
        case unit_type
        when UNIT_METERS
          100.0 / 2.54
        when UNIT_CENTIMETERS
          1.0 / 2.54
        when UNIT_MILLIMETERS
          0.1 / 2.54
        when UNIT_FEET
          12.0
        when UNIT_INCHES
          1
        end
      end
      private :get_unit_ratio

      def stl_dialog
        # Since WebDialogs under OSX isn't truly modal there is a chance the user
        # can click the Options button while the window is already open. We then
        # just bring it to the front.
        # 
        # The reference is being released when the window is closed so it's
        # easier to develop - make updates. Otherwise the WebDialog object would
        # have been cached. And it also should ensure it's garbage collected.
        if @option_window && @option_window.visible?
          @option_window.bring_to_front
          return false
        end

        html_source = File.join(PLUGIN_PATH, 'html', 'importer.html')

        window_options = {
          :dialog_title     => STL.translate('Import STL Options'),
          :preferences_key  => false,
          :scrollable       => false,
          :resizable        => false,
          :left             => 300,
          :top              => 200,
          :width            => 330,
          :height           => 265
        }

        window = UI::WebDialog.new(window_options)
        window.extend(WebDialogExtensions)
        window.set_size(window_options[:width], window_options[:height])
        window.navigation_buttons_enabled = false

        window.add_action_callback('Window_Ready') { |dialog, params|
          # Read import settings.
          merge_faces     = read_setting('merge_faces',     @stl_merge)
          current_unit    = read_setting('import_units',    @stl_units)
          preserve_origin = read_setting('preserve_origin', @stl_preserve_origin)
          # Ensure they are in proper format. (Recovers from old settings)
          merge_faces     = ( merge_faces == true )
          current_unit    = current_unit.to_i
          preserve_origin = ( preserve_origin == true )
          # Update webdialog values.
          dialog.update_value('chkMergeCoplanar', merge_faces)
          dialog.update_value('lstUnits', current_unit)
          dialog.update_value('chkPreserveOrigin', preserve_origin)
          # Localize UI
          ui_strings = window.parse_params(params)
          translated_ui_strings = ui_strings.map { |string|
            STL.translate(string)
          }
          window.call_function('UI.update_strings', translated_ui_strings)
        }

        window.add_action_callback('Event_Accept') { |dialog, params|
          # Get data from webdialog.
          options = {
            :merge_coplanar   => dialog.get_element_value('chkMergeCoplanar'),
            :units            => dialog.get_element_value('lstUnits'),
            :preserve_origin  => dialog.get_element_value('chkPreserveOrigin')
          }
          dialog.close
          #p options # DEBUG
          # Convert to Ruby values.
          @stl_merge            = (options[:merge_coplanar] == 'true')
          @stl_preserve_origin  = (options[:preserve_origin] == 'true')
          @stl_units            = options[:units].to_i
          # Store last used preferences.
          write_setting('merge_faces',     @stl_merge)
          write_setting('import_units',    @stl_units)
          write_setting('preserve_origin', @stl_preserve_origin)
        }

        window.add_action_callback('Event_Cancel') { |dialog, params|
          dialog.close
        }
        window.set_on_close {
          @option_window = nil # (See comment at beginning of method.)
        }

        window.set_file( html_source )
        window.show_modal
        @option_window = window # (See comment at beginning of method.)
        true
      end
      private :stl_dialog

      # Wrapper to shorten the syntax and create a central place to modify in case
      # preferences are stored differently in the future.
      def read_setting(key, default)
        Sketchup.read_default(PREF_KEY, key, default)
      end
      private :read_setting

      # Wrapper to shorten the syntax and create a central place to modify in case
      # preferences are stored differently in the future.
      def write_setting(key, value)
        Sketchup.write_default(PREF_KEY, key, value)
      end
      private :write_setting

    end # class Importer

  end # module STL
end # module CommunityExtensions

unless file_loaded?(__FILE__)
  Sketchup.register_importer(CommunityExtensions::STL::Importer.new)
  file_loaded(__FILE__)
end
