# Copyright 2012-2015 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl
#
# Importer

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

      # Ruby #pack / #unpack directives:
      # http://www.ruby-doc.org/core-2.0.0/String.html#method-i-unpack
      UINT16 = 'v'.freeze
      UINT32 = 'V'.freeze
      REAL32 = 'e'.freeze

      UINT16_BYTE_SIZE = 2 # 16 bits
      UINT32_BYTE_SIZE = 4 # 32 bits
      REAL32_BYTE_SIZE = 4 # 32 bits

      BINARY_HEADER_SIZE = 80 # UINT8[80]
      BINARY_POINT3D_SIZE = REAL32_BYTE_SIZE * 3
      BINARY_VECTOR3D_SIZE = REAL32_BYTE_SIZE * 3

      BINARY_POINT3D = (REAL32 * 3).freeze
      BINARY_VECTOR3D = (REAL32 * 3).freeze

      MESH_NO_SOFTEN_OR_SMOOTH = 0


      def initialize
        @stl_units = UNIT_MILLIMETERS
        @stl_merge = false
        @stl_preserve_origin = true
        @stl_repair = true
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

      def load_file(path, status)
        begin
          start = Time.now
          status = main(path)
          milli = (Time.now - start) * 1000.0
          puts File.basename(path)
          puts "Import took #{milli} ms"
        rescue => exception
          puts exception.message
          puts exception.backtrace.join("\n")
          status = IMPORT_FAILED
        end
        return status
      end

      def main(filename)
        file_type = detect_file_type(filename)
        return IMPORT_FAILED if file_type.nil?
        #p file_type
        # Read import settings.
        @stl_merge           = read_setting('merge_faces',     @stl_merge)
        @stl_units           = read_setting('import_units',    @stl_units)
        @stl_preserve_origin = read_setting('preserve_origin', @stl_preserve_origin)
        @stl_repair          = read_setting('repair',          @stl_repair)
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
        if file_type == :ascii
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
        if @stl_repair && !is_solid?(container.entities)
          Sketchup.status_text = STL.translate('Repairing geometry...')
          puts 'Repairing...' # TODO(thomthom): Temp debug! Remove!
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

      #
      # A simple check for the word 'solid' to detect an ascii .stl file is
      # not sufficient - some binary .stl files break convention by also
      # starting with the word 'solid'.
      #
      def detect_file_type(file_name)
        face_count = nil
        # Ensure to open the file in binary mode with no encoding.
        filemode = 'rb'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        File.open(file_name, filemode) {|file|
          file.seek(80, IO::SEEK_SET)
          face_count = file.read(4).unpack('i')[0]
        }
        # The source of the magic numbers 80, 4 and 50...
        # http://orion.math.iastate.edu/burkardt/data/stl/stl.html
        # A binary STL file has the following structure:
        #   An 80 byte ASCII header that can be used as a title.
        #   A 4 byte unsigned long integer, the number of facets.
        #   A facet record of 50 bytes (for each facet)
        #     The normal vector,        3 floating values of 4 bytes each;
        #     Vertex 1 XYZ coordinates, 3 floating values of 4 bytes each;
        #     Vertex 2 XYZ coordinates, 3 floating values of 4 bytes each;
        #     Vertex 3 XYZ coordinates, 3 floating values of 4 bytes each;
        #     An unsigned integer     , 2 bytes that should be zero;
        expected_file_size = 80 + 4 + 50 * face_count
        actual_file_size   = File.size(file_name)
        if expected_file_size == actual_file_size
          return :binary
        else
          return :ascii
        end
      rescue => exception
        puts "#{exception.message}\n\n" + exception.backtrace.join("\n")
        return nil
      end
      private :detect_file_type

      def do_msg(msg)
        return UI.messagebox(msg, MB_YESNO)
      end
      private :do_msg

      def stl_binary_import(filename, try = 1)
        unit_ratio_scale = get_unit_ratio(@stl_units)
        number_of_triangles = 0
        points = []

        # Ensure to open the file in binary mode with no encoding.
        filemode = 'rb'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        File.open(filename, filemode) { |file|
          # Skip the header block because we don't need it. There doesn't appear
          # to be anyone implementing any data into this.
          file.seek(BINARY_HEADER_SIZE, IO::SEEK_SET)

          # Read how many triangles there are should be.
          number_of_triangles = file.read(UINT32_BYTE_SIZE).unpack(UINT32)[0]

          # Read geometry data.
          number_of_triangles.times { |i|
            normal = file.read(BINARY_VECTOR3D_SIZE).unpack(BINARY_VECTOR3D)

            vertex1 = file.read(BINARY_POINT3D_SIZE).unpack(BINARY_POINT3D)
            vertex1.map!{ |value| value * unit_ratio_scale }

            vertex2 = file.read(BINARY_POINT3D_SIZE).unpack(BINARY_POINT3D)
            vertex2.map!{ |value| value * unit_ratio_scale }

            vertex3 = file.read(BINARY_POINT3D_SIZE).unpack(BINARY_POINT3D)
            vertex3.map!{ |value| value * unit_ratio_scale }

            # Read attribute data.
            attributes_byte_size = file.read(UINT16_BYTE_SIZE).unpack(UINT16)[0]
            # NOTE: This value appear to be junk value in some files. Files can
            # have non-zero attribute-byte-size values, yet there is no extra
            # data following this data chunk. Therefore this value is ignored.
            #file.seek(attributes_byte_size, IO::SEEK_CUR)

            points << [vertex1, vertex2, vertex3]
          }
        } # File.open

        # Generate a PolygonMesh from the parsed STL data.
        number_of_points = 3 * number_of_triangles
        mesh = Geom::PolygonMesh.new(number_of_points, number_of_triangles)
        points.each { |triangle| mesh.add_polygon(triangle) }

        # Create SketchUp entities from the PolygonMesh.
        entities = Sketchup.active_model.entities
        if entities.length > 0
          group = entities.add_group
          entities = group.entities
        end
        entities.fill_from_mesh(mesh, false, MESH_NO_SOFTEN_OR_SMOOTH)
        entities
      end
      private :stl_binary_import

      def stl_ascii_import(filename, try = 1)
        unit_ratio_scale = get_unit_ratio(@stl_units)
        polygons = []
        triangle = []
        num_vertices = 0
        # Ensure to open the file in with no encoding.
        filemode = 'r'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        # TODO(thomthom): This is currently making a lot of assumptions and no
        # validation check of the format. It'd be good to improve this.
        File.open(filename, filemode) { |file|
          file.each_line { |line|
            line.chomp!
            if line[/vertex/]
              num_vertices += 1
              entity_type, *point = line.split
              point.map! { |value| value.to_f * unit_ratio_scale }
              triangle << point
              if num_vertices == 3
                polygons.push(triangle.dup)
                triangle = []
                num_vertices = 0
              end
            end
          }
        }
        if polygons.length == 0
          if try == 1
            return stl_binary_import(filename, 2)
          end
        end
        mesh = Geom::PolygonMesh.new(3 * polygons.length, polygons.length)
        polygons.each{ |triangle| mesh.add_polygon(triangle) }
        entities = Sketchup.active_model.entities
        if entities.length > 0
          group = entities.add_group
          entities = group.entities
        end
        entities.fill_from_mesh(mesh, false, MESH_NO_SOFTEN_OR_SMOOTH)
        entities
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
          :height           => 300
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
          stl_repair      = read_setting('repair',          @stl_stl_repair)
          # Ensure they are in proper format. (Recovers from old settings)
          merge_faces     = ( merge_faces == true )
          current_unit    = current_unit.to_i
          preserve_origin = ( preserve_origin == true )
          stl_repair      = ( stl_repair == true )
          # Update webdialog values.
          dialog.update_value('chkMergeCoplanar', merge_faces)
          dialog.update_value('lstUnits', current_unit)
          dialog.update_value('chkPreserveOrigin', preserve_origin)
          dialog.update_value('chkRepair', stl_repair)
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
            :preserve_origin  => dialog.get_element_value('chkPreserveOrigin'),
            :repair           => dialog.get_element_value('chkRepair')
          }
          dialog.close
          #p options # DEBUG
          # Convert to Ruby values.
          @stl_merge            = (options[:merge_coplanar] == 'true')
          @stl_preserve_origin  = (options[:preserve_origin] == 'true')
          @stl_units            = options[:units].to_i
          @stl_stl_repair       = (options[:repair] == 'true')
          # Store last used preferences.
          write_setting('merge_faces',     @stl_merge)
          write_setting('import_units',    @stl_units)
          write_setting('preserve_origin', @stl_preserve_origin)
          write_setting('repair',          @stl_stl_repair)
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

      unless file_loaded?(self.name)
        Sketchup.register_importer(CommunityExtensions::STL::Importer.new)
        file_loaded(self.name)
      end

    end # class Importer
  end # module STL
end # module CommunityExtensions
