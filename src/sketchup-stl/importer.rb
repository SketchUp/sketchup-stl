# jf_stl_importer.rb - Imports ascii and binary .stl file in SketchUp
#
# Copyright (C) 2010 Jim Foltz (jim.foltz@gmail.com)
#
# License: Apache License, Version 2.0

require 'sketchup'

module CommunityExtensions
  module STL
    class Importer < Sketchup::Importer

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

      BINARY_HEADER_SIZE   = 80 # UINT8[80]
      BINARY_POINT3D_SIZE  = REAL32_BYTE_SIZE * 3
      BINARY_VECTOR3D_SIZE = REAL32_BYTE_SIZE * 3

      BINARY_POINT3D  = (REAL32 * 3).freeze
      BINARY_VECTOR3D = (REAL32 * 3).freeze

      MESH_NO_SOFTEN_OR_SMOOTH = 0


      def initialize
        @stl_units           = UNIT_MILLIMETERS
        @stl_merge           = false
        @stl_preserve_origin = true
        @option_window       = nil # (See comment at top of `stl_dialog()`.)
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
        window_options = {
          :title           => STL.translate('STL Import Options'),
          :preferences_key => PREF_KEY,
          :width           => 300,
          :height          => 225,
          :modal           => false
        }
        merge_faces     = read_setting('merge_faces',     @stl_merge)
        current_unit    = read_setting('import_units',    @stl_units)
        preserve_origin = read_setting('preserve_origin', @stl_preserve_origin)

        window = SKUI::Window.new(window_options)
        grp_geometry = SKUI::Groupbox.new(STL.translate('Geometry'))
        grp_geometry.position(5, 5)
        grp_geometry.right  = 5
        grp_geometry.height = 75
        window.add_control(grp_geometry)

        chk_merge_coplanar = SKUI::Checkbox.new(STL.translate('Merge coplanar faces'))
        chk_merge_coplanar.name    = :stl_merge
        chk_merge_coplanar.checked = merge_faces
        chk_merge_coplanar.top     = 25
        chk_merge_coplanar.left    = 50
        grp_geometry.add_control(chk_merge_coplanar)

        grp_scale                 = SKUI::Groupbox.new(STL.translate('Scale'))
        grp_scale.position(5, 65)
        grp_scale.right           = 5
        grp_scale.height          = 100
        window.add_control(grp_scale)

        units = ['Model Units', 'Meters', 'Centimeters', 'Millimeters', 'Inches', 'Feet']
        units_translated = units.map { |unit| STL.translate(unit) }

        lbl_units      = SKUI::Label.new(STL.translate('Units:'))
        lbl_units.left = 10
        grp_scale.add_control(lbl_units)

        lst_units       = SKUI::Listbox.new(units_translated)
        lst_units.name  = :stl_units
        lst_units.value = current_unit
        lst_units.left  = 50
        grp_scale.add_control(lst_units)

        chk_origin = SKUI::Checkbox.new(STL.translate('Preserve drawing origin'))
        chk_origin.name    = :stl_preserve_origin
        chk_origin.checked = preserve_origin
        chk_origin.top     = 50
        chk_origin.left    = 50
        grp_scale.add_control(chk_origin)

        btn_cancel = SKUI::Button.new(STL.translate('Cancel')) { |control|
          control.window.close
        }
        btn_cancel.position(-5, -5)
        window.add_control(btn_cancel)

        btn_import = SKUI::Button.new(STL.translate("Accept")) { |control|
          @stl_merge           = control.window[:stl_merge].checked?
          @stl_preserve_origin = control.window[:stl_preserve_origin].checked?
          @stl_units           = control.window[:stl_units].value
          write_setting('merge_faces'     , @stl_merge)
          write_setting('import_units'    , @stl_units)
          write_setting('preserve_origin' , @stl_preserve_origin)
          control.window.close
        }
        btn_import.position(-85, -5)
        window.add_control(btn_import)

        window.show
      end

      def load_file(path,status)
        begin
          status = main(path)
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
        #unit_ratio_scale = get_unit_ratio(@stl_units)
        unit_ratio_scale = scale_factor(@stl_units)
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
        unit_ratio_scale = scale_factor(@stl_units)
        polygons         = []
        triangle         = []
        num_vertices     = 0
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
          group    = entities.add_group
          entities = group.entities
        end
        entities.fill_from_mesh(mesh, false, MESH_NO_SOFTEN_OR_SMOOTH)
        entities
      end


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

      def model_units
        case Sketchup.active_model.options['UnitsOptions']['LengthUnit']
        when UNIT_METERS
          'Meters'
        when UNIT_CENTIMETERS
          'Centimeters'
        when UNIT_MILLIMETERS
          'Millimeters'
        when UNIT_FEET
          'Feet'
        when UNIT_INCHES
          'Inches'
        end
      end

      def scale_factor(unit_key)
        if unit_key == 'Model Units'
          selected_key = model_units()
        else
          selected_key = unit_key
        end
        case selected_key
        when 'Meters'
          factor = 1.m
        when 'Centimeters'
          factor = 1.cm
        when 'Millimeters'
          factor = 1.mm
        when 'Feet'
          factor = 1.feet
        when 'Inches'
          factor = 1.0
        end
        factor
      end

    end # class Importer
  end # module STL
end # module CommunityExtensions

unless file_loaded?(__FILE__)
  Sketchup.register_importer(CommunityExtensions::STL::Importer.new)
  file_loaded(__FILE__)
end
