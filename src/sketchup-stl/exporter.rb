# SketchUp to DXF STL Converter
# Last edited: February 18, 2011
# Authors: Nathan Bromham, Konrad Shroeder (http://www.guitar-list.com/)
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
  module STL
    module Exporter

      # Load SKUI lib
      load File.join(File.dirname(__FILE__), 'SKUI', 'embed_skui.rb')
      ::SKUI.embed_in(self)

      STL_ASCII  = 'ASCII'.freeze
      STL_BINARY = 'Binary'.freeze

      OPTIONS = {
        'selection_only' => false,
        'export_units'   => 'Model Units',
        'stl_format'     => STL_ASCII
      }

      PREF_KEY = 'CommunityExtensions\STL\Exporter'.freeze

      def self.file_extension
        'stl'
      end

      def self.model_name
        title = Sketchup.active_model.title
        title = "Untitled-#{Time.now.to_i.to_s(16)}" if title.empty?
        title
      end

      def self.select_export_file
        template  = STL.translate('%s file location')
        file_name = "#{model_name()}.#{file_extension()}"
        dlg_title = sprintf(template, file_name)
        directory = nil
        path = UI.savepanel(dlg_title, directory, file_name)
      end

      def self.export(path, options = OPTIONS)
        filemode = 'w'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        file = File.new(path , filemode)
        if options['stl_format'] == STL_BINARY
          file.binmode
          @write_face = method(:write_face_binary)
        else
          @write_face = method(:write_face_ascii)
        end
        scale = scale_factor(options['export_units'])
        write_header(file, model_name(), options['stl_format'])
        if options['selection_only']
          export_ents = Sketchup.active_model.selection
        else
          export_ents = Sketchup.active_model.active_entities
        end
        face_count = find_faces(file, export_ents, scale, Geom::Transformation.new)
        write_footer(file, face_count, model_name(), options['stl_format'])
      end

      def self.find_faces(file, entities, scale, tform)
        face_count = 0
        entities.each do |entity|
          if entity.is_a?(Sketchup::Face)
            write_face(file, entity, scale, tform)
            face_count += 1
          elsif entity.is_a?(Sketchup::Group) ||
            entity.is_a?(Sketchup::ComponentInstance)
            entity_definition = Utils.definition(entity)
            find_faces(
              file,
              entity_definition.entities,
              scale,
              tform * entity.transformation
            )
          end
        end
        face_count
      end

      def self.write_face(file, face, scale, tform)
        mesh = face.mesh(7)
        mesh.transform!(tform)
        @write_face.call(file, scale, mesh)
      end

      def self.write_face_ascii(file, scale, mesh)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if (polygon.length == 3)
            norm = mesh.normal_at(polygon[0].abs)
            file.write("facet normal #{norm.x} #{norm.y} #{norm.z}\n")
            file.write("  outer loop\n")
            for j in 0..2 do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * scale}
              file.write("    vertex #{pt.x} #{pt.y} #{pt.z}\n")
            end
            file.write("  endloop\nendfacet\n")
          end
        end
      end

      def self.write_face_binary(file, scale, mesh)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if (polygon.length == 3)
            norm = mesh.normal_at(polygon[0].abs)
            file.write(norm.to_a.pack("e3"))
            for j in 0..2 do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * scale}
              file.write(pt.pack("e3"))
            end
            file.write([0].pack("v"))
          end
        end
      end

      def self.write_header(file, model_name, format)
        if format == STL_ASCII
          file.write("solid #{model_name}\n")
        else
          file.write(["SketchUp STL #{model_name}"].pack("A80"))
          # 0xffffffff is a place-holder value. In the binary format,
          # this value is updated in the write_footer method.
          file.write([0xffffffff].pack('V'))
        end
      end

      def self.write_footer(file, face_count, model_name, format)
        if format == STL_ASCII
          file.write("endsolid #{model_name}\n")
        else
          # binary - update facet count
          file.flush
          file.seek(80)
          file.write([face_count].pack('V'))
        end
        file.close
      end

      # Wrapper to shorten the syntax and create a central place to modify in case
      # preferences are stored differently in the future.
      def self.read_setting(key, default)
        Sketchup.read_default(PREF_KEY, key, default)
      end

      # Wrapper to shorten the syntax and create a central place to modify in case
      # preferences are stored differently in the future.
      def self.write_setting(key, value)
        Sketchup.write_default(PREF_KEY, key, value)
      end

      def self.model_units
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

      def self.scale_factor(unit_key)
        if unit_key == 'Model Units'
          selected_key = model_units()
        else
          selected_key = unit_key
        end
        case selected_key
        when 'Meters'
          factor = 0.0254
        when 'Centimeters'
          factor = 2.54
        when 'Millimeters'
          factor = 25.4
        when 'Feet'
          factor = 0.0833333333333333
        when 'Inches'
          factor = 1.0
        end
        factor
      end

      def self.do_options

        # Read last saved options
        ['selection_only', 'stl_format', 'export_units'].each do |key|
          OPTIONS[key] = read_setting(key, OPTIONS[key])
        end

        units = ['Model Units', 'Meters', 'Centimeters', 'Millimeters', 'Inches', 'Feet']
        units_translated = units.map { |unit| STL.translate(unit) }

        formats = [STL_ASCII, STL_BINARY]
        formats_translated = formats.map { |format| STL.translate(format) }

        # Columns and Rows for control alignment
        col = [0, 10, 110]
        first_row = 7
        vspace = 30
        row = (0..4).map{|e| e * vspace + first_row}
        row.unshift(0)

        window_options = {
          :title           => STL.translate('STL Export Options'),
          :preferences_key => PREF_KEY,
          :height          => 160,
          :width           => 290,
          :modal           => true
        }
        window = SKUI::Window.new(window_options)

        # Row 1 Export Selected
        chk_selection = SKUI::Checkbox.new(
          'Export selected geometry only.',
          OPTIONS['selection_only']
        )
        chk_selection.position(col[1], row[1])
        chk_selection.check if OPTIONS['selection_only']
        chk_selection.on(:change) { |control|
          OPTIONS['selection_only'] = control.checked?
        }
        window.add_control(chk_selection)

        #
        # Row 2 Export Units
        #
        lst_units = SKUI::Listbox.new(units_translated)
        lst_units.position(col[2], row[2])
        lst_units.width = 169
        lst_units.value = STL.translate(OPTIONS['export_units'])
        lst_units.on(:change) { |control, value|
          unit_index = units_translated.index(value)
          OPTIONS['export_units'] = units[unit_index]
        }
        window.add_control(lst_units)

        lbl_units = SKUI::Label.new(STL.translate('Export unit:'), lst_units)
        lbl_units.position(col[1], row[2])
        window.add_control(lbl_units)

        #
        # Row 3 File Format field
        #
        lst_format = SKUI::Listbox.new(formats_translated)
        lst_format.value = lst_format.items.first
        lst_format.position(col[2], row[3])
        lst_format.width = 169
        lst_format.value = STL.translate(OPTIONS['stl_format'])
        lst_format.on(:change) { |control, value|
          format_index = formats_translated.index(value)
          OPTIONS['stl_format'] = formats[format_index]
        }
        window.add_control(lst_format)

        lbl_type = SKUI::Label.new(STL.translate('File format:'), lst_format)
        lbl_type.position(col[1], row[3])
        window.add_control(lbl_type)

        #
        # Export and Cancel Buttons
        #
        btn_export = SKUI::Button.new('Export') { |control|

          write_setting('export_units'   , OPTIONS['export_units'])
          write_setting('stl_format'     , OPTIONS['stl_format'])
          write_setting('selection_only' , OPTIONS['selection_only'])

          path = select_export_file()

          export(path, OPTIONS) unless path.nil?
          control.window.close
        }

        btn_export.position(125, -5)
        window.add_control(btn_export)

        btn_cancel = SKUI::Button.new('Cancel') { |control|
          control.window.close
        }
        btn_cancel.position(-5, -5)
        window.add_control(btn_cancel)

        window.default_button = btn_export
        window.show
      end # do_options

      unless file_loaded?(__FILE__)
        # Pick menu indexes for where to insert the Export menu. These numbers
        # where picked when SketchUp 8 M4 was the latest version.
        if IS_OSX
          insert_index = 19
        else
          insert_index = 17
        end
        # (i) The menu_index argument isn't supported by older versions.
        if Sketchup::Menu.instance_method(:add_item).arity == 1
          item = UI.menu('File').add_item(STL.translate('Export STL...')) {
            do_options
          }
        else
          item = UI.menu('File').add_item(STL.translate('Export STL...'), insert_index) {
            do_options
          }
        end
        UI.menu('File').set_validation_proc(item) do
          if Sketchup.active_model.entities.length == 0
            MF_GRAYED
          else
            MF_ENABLED
          end
        end
        file_loaded(__FILE__)
      end

    end # module Exporter
  end # module STL
end # module CommunityExtensions
