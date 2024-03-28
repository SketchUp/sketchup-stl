# Copyright 2012-2015 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl
#
# Exporter

require 'sketchup'

module CommunityExtensions
  module STL
    module Exporter

      # Load SKUI lib
      load File.join(PLUGIN_PATH, 'SKUI', 'embed_skui.rb')
      ::SKUI.embed_in(self)

      STL_ASCII  = 'ASCII'.freeze
      STL_BINARY = 'Binary'.freeze

      OPTIONS = {
        'export_units'   => 'Model Units',
        'stl_format'     => STL_ASCII,
        'component_selection' => 'One file for each Main Component'
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
        title_template  = STL.translate('%s file location')
        default_filename = "#{model_name}.#{file_extension}"
        dialog_title = sprintf(title_template, default_filename)
        directory = Sketchup.active_model.path
        filename = UI.savepanel(dialog_title, directory, default_filename)
        # Ensure the file has a file extensions if the user omitted it.
        if filename && File.extname(filename).empty?
          filename = "#{filename}.#{file_extension}"
        end
        filename
      end

      def self.export(path, export_entities, options = OPTIONS)
         filemode = 'w'
         if RUBY_VERSION.to_f > 1.8
            filemode << ':ASCII-8BIT'
         end
        if OPTIONS['component_selection'] == 'One file for each Main Component'
          for entity in export_entities
            suffix_filename = File.basename(path, File.extname(path))
            file_path = File.dirname(path) +'/' + suffix_filename + '_' + Utils.definition(entity).name + '.stl'
            file = File.new(file_path , filemode)
            if options['stl_format'] == STL_BINARY
                file.binmode
                @write_face = method(:write_face_binary)
            else
                @write_face = method(:write_face_ascii)
            end
            scale = scale_factor(options['export_units'])
            write_header(file, model_name, options['stl_format'])
            facet_count = find_faces(file, [entity], 0, scale, Geom::Transformation.new)
            write_footer(file, facet_count, model_name, options['stl_format'])
          end

        else 
          file = File.new(path , filemode)
          if options['stl_format'] == STL_BINARY
              file.binmode
              @write_face = method(:write_face_binary)
          else
              @write_face = method(:write_face_ascii)
          end
          scale = scale_factor(options['export_units'])
          write_header(file, model_name, options['stl_format'])
          facet_count = find_faces(file, export_entities, 0, scale, Geom::Transformation.new)
          write_footer(file, facet_count, model_name, options['stl_format'])
        end
      end

      def self.find_faces(file, entities, facet_count, scale, tform)
        entities.each do |entity|
          next if entity.hidden? || !entity.layer.visible?
          if entity.is_a?(Sketchup::Face)
            facet_count += write_face(file, entity, scale, tform)
          elsif entity.is_a?(Sketchup::Group) ||
            entity.is_a?(Sketchup::ComponentInstance)
            entity_definition = Utils.definition(entity)
            facet_count += find_faces(
              file,
              entity_definition.entities,
              0,
              scale,
              tform * entity.transformation
            )
          end
        end
        facet_count
      end

      def self.write_face(file, face, scale, tform)
        normal = face.normal
        normal.transform!(tform)
        normal.normalize!
        mesh = face.mesh(0)
        mesh.transform!(tform)
        facets_written = @write_face.call(file, scale, mesh, normal)
        return(facets_written)
      end

      def self.write_face_ascii(file, scale, mesh, normal)
        facets_written = 0
        points = mesh.points
        return facets_written if points.empty? # Issue 173
        vertex_order = get_vertex_order(points, normal)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if polygon.length == 3
            file.write("facet normal #{normal.x} #{normal.y} #{normal.z}\n")
            file.write("  outer loop\n")
            for j in vertex_order do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * scale}
              file.write("    vertex #{pt.x} #{pt.y} #{pt.z}\n")
            end
            file.write("  endloop\nendfacet\n")
            facets_written += 1
          end
        end
        return facets_written
      end

      def self.write_face_binary(file, scale, mesh, normal)
        facets_written = 0
        points = mesh.points
        return facets_written if points.empty? # Issue 173
        vertex_order = get_vertex_order(points, normal)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if (polygon.length == 3)
            # e - Float: single-precision, little endian byte order
            file.write(normal.to_a.pack("e3"))
            for j in vertex_order do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * scale}
              file.write(pt.pack("e3"))
            end
            # 2-byte "Attribute byte count" spacer. Nonstandard use by some stl software
            # to store color data. Was never widely supported. Should be 0.
            # "S<" - 16-bit unsigned integer, little-endian
            file.write([0].pack("S<"))
            facets_written += 1
          end
        end
        return(facets_written)
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

      def self.write_footer(file, facet_count, model_name, format)
        if format == STL_ASCII
          file.write("endsolid #{model_name}\n")
        else
          # binary - update facet count
          file.flush
          file.seek(80)
          file.write([facet_count].pack('V'))
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
          selected_key = model_units
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

      # Flipped instances in SketchUp may not follow the right-hand rule,
      # but the STL format expects vertices ordered by the right-hand rule.
      # If the SketchUp::Face normal does not match the normal calculated
      # using the right-hand rule, then reverse the vertex order written
      # to the .stl file.
      def self.get_vertex_order(positions, face_normal)
        calculated_normal = (positions[1] - positions[0]).cross( (positions[2] - positions[0]) )
        order = [0, 1, 2]
        order.reverse! if calculated_normal.dot(face_normal) < 0
        order
      end

      # Return model.active_entities, selection, or nil
      def self.get_export_entities
        export_ents = nil
        if OPTIONS['component_selection'] == 'One file for each Main Component'
          model = Sketchup.active_model
          export_ents = model.entities.grep(Sketchup::ComponentInstance)
        elsif OPTIONS['component_selection'] == 'Selection Only'
          if Sketchup.active_model.selection.length > 0
            export_ents = Sketchup.active_model.selection
          else
            msg = "SketchUp STL Exporter:\n\n"
            msg << "You have chosen \"Export only current selection\", but nothing is selected."
            msg << "\n\nWould you like to export the entire model?"
            if UI.messagebox(msg, MB_YESNO) == IDYES
              export_ents = Sketchup.active_model.active_entities
            end
          end
        else
          export_ents = Sketchup.active_model.active_entities
        end
        export_ents
      end


      def self.do_options

        # Read last saved options
        ['stl_format', 'export_units','component_selection'].each do |key|
          OPTIONS[key] = read_setting(key, OPTIONS[key])
        end

        units = ['Model Units', 'Meters', 'Centimeters', 'Millimeters', 'Inches', 'Feet']
        units_translated = units.map { |unit| STL.translate(unit) }
        export_type = ['Full Model', 'One file for each Main Component', 'Selection Only']
        component_selection = export_type.map { |export_type| STL.translate(export_type) }

        formats = [STL_ASCII, STL_BINARY]
        formats_translated = formats.map { |format| STL.translate(format) }

        # Columns and Rows for control alignment
        col = [0, 10, 110]
        first_row = 7
        vspace = 30
        row = (0..5).map{|e| e * vspace + first_row}
        row.unshift(0)

        window_options = {
          :title           => STL.translate('STL Export Options'),
          :preferences_key => PREF_KEY,
          :height          => 160,
          :width           => 300,
          :modal           => true
        }
        window = SKUI::Window.new(window_options)

        lst_component_selection = SKUI::Listbox.new(component_selection)
        lst_component_selection.position(col[2], row[1])
        lst_component_selection.width = 169
        lst_component_selection.value = STL.translate(OPTIONS['component_selection'])
        lst_component_selection.on(:change) { |control, value|
          component_selection_index = component_selection.index(value)
          OPTIONS['component_selection'] = export_type[component_selection_index]
        }
        window.add_control(lst_component_selection)

        lst_component_selection = SKUI::Label.new(STL.translate('Export type:'), lst_component_selection)
        lst_component_selection.position(col[1], row[1])
        window.add_control(lst_component_selection)

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
          write_setting('component_selection' , OPTIONS['component_selection'])
          control.window.close
          export_entities = get_export_entities
          if export_entities
            
            path = select_export_file            
             begin
                export(path, export_entities, OPTIONS) unless path.nil?
             rescue => exception
                msg = "SketchUp STL Exporter:\n"
                msg << "An error occured during export.\n\n"
                msg << exception.message << "\n"
                msg << exception.backtrace.join("\n")
                UI.messagebox(msg, MB_MULTILINE)
             end
          end
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


      # Main entry point via menu item.
      # Display a message and exit if the model is empty, else
      # show the export dialog.
      def self.main
        if Sketchup.active_model.active_entities.length == 0
          msg = "SketchUp STL Exporter:\n\n"
          msg << STL.translate("The model is empty - there is nothing to export.")
          UI.messagebox(msg, MB_OK)
        else
          do_options
        end
      end


      unless file_loaded?(self.name)
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
            main
          }
        else
          item = UI.menu('File').add_item(STL.translate('Export STL...'), insert_index) {
            main
          }
        end
        file_loaded(self.name)
      end


    end # module Exporter
  end # module STL
end # module CommunityExtensions
