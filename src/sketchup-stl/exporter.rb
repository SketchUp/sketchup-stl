# SketchUp to DXF STL Converter
# Last edited: February 18, 2011
# Authors: Nathan Bromham, Konrad Shroeder (http://www.guitar-list.com/)
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
  module STL
    module Exporter

      STL_ASCII  = 'ascii'.freeze
      STL_BINARY = 'binary'.freeze

      PREF_KEY = 'CommunityExtensions\STL\Exporter'.freeze

      def self.export_mesh_file
        model = Sketchup.active_model
        if model.active_entities.length == 0
          return UI.messagebox(STL.translate('Nothing to export.'))
        end
        model_name = File.basename(model.path, '.skp')
        if model_name == ''
          model_name = 'untitled'
        end
        @stl_conv = 1.0
        @face_count = 0
        @line_count = 0
        if model.selection.empty?
          answer = UI.messagebox(
            STL.translate('No objects selected. Export entire model?'),
            MB_YESNO
          )
          if answer == IDYES
            export_ents = model.entities
          else
            export_ents = model.selection
          end
        else
          export_ents = Sketchup.active_model.selection
        end
        if export_ents.length > 0
          # Get DXF export option.
          file_type='stl'
          # Get Export options.
          options = options_dialog
          return if options == false

          @stl_conv = options[0]
          @stl_type = options[1].downcase

          # Get exported file name and export.
          description = STL.translate('%s file location')
          out_name = UI.savepanel(sprintf(description, file_type.upcase), nil,
                                  "#{model_name}.#{file_type}")
          if out_name
            @mesh_file = File.new(out_name , 'w')  
            if @stl_type == STL_BINARY
              @mesh_file.binmode
              @write_face = method(:write_face_binary)
            else
              @write_face = method(:write_face_ascii)
            end
            write_header(model_name)

            # Recursively export faces and edges, exploding groups as we go.
            # Count "other" objects we can't parse.
            others = find_faces(0, export_ents, Geom::Transformation.new)
            write_footer(model_name)
            message = STL.translate("%i facets exported\n%i objects ignored")
            UI.messagebox(sprintf(message, @face_count, others))
          end
        end
      end

      def self.find_faces(others, entities, tform)
        entities.each do |entity|
          if entity.is_a?(Sketchup::Face)
            write_face(entity, tform)     
          elsif entity.is_a?(Sketchup::Group) ||
            entity.is_a?(Sketchup::ComponentInstance)
            if entity.is_a?(Sketchup::Group)
              # (!) Beware - Due to a SketchUp bug this can be incorrect.
              # Fix later.
              definition = entity.entities.parent
            else
              definition = entity.definition
            end
            others = find_faces(others, definition.entities,
                                tform * entity.transformation)
          else
            others = others + 1
          end
        end # each
        others
      end

      def self.write_face_ascii(mesh)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if (polygon.length == 3)
            norm = mesh.normal_at(polygon[0].abs)
            @mesh_file.write("facet normal #{norm.x} #{norm.y} #{norm.z}\n")
            @mesh_file.write("  outer loop\n")
            for j in 0..2 do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * @stl_conv}
              @mesh_file.write("    vertex #{pt.x} #{pt.y} #{pt.z}\n")
            end
            @mesh_file.write( "  endloop\nendfacet\n")
          end
        end
      end

      def self.write_face_binary(mesh)
        polygons = mesh.polygons
        polygons.each do |polygon|
          if (polygon.length == 3)
            norm = mesh.normal_at(polygon[0].abs)
            @mesh_file.write(norm.to_a.pack("e3"))
            for j in 0..2 do
              pt = mesh.point_at(polygon[j].abs)
              pt = pt.to_a.map{|e| e * @stl_conv}
              @mesh_file.write(pt.pack("e3"))
            end
            @mesh_file.write([0].pack("v"))
          end
        end
      end

      def self.write_face(face, tform)
        mesh = face.mesh(7)
        mesh.transform!(tform)
        @write_face.call(mesh)
        @face_count += 1
      end

      def self.write_header(model_name)
        if @stl_type == STL_ASCII
          @mesh_file.write("solid #{model_name}\n")
        else
          @mesh_file.write(["SketchUp STL #{model_name}"].pack("A80"))
          # 0xffffffff is a place-holder value. In the binary format,
          # this value is updated in the write_footer method.
          @mesh_file.write([0xffffffff].pack('V'))
        end
      end

      def self.write_footer(model_name)
        if @stl_type == STL_ASCII
          @mesh_file.write("endsolid #{model_name}\n")
        else
          # binary - update facet count
          @mesh_file.flush
          @mesh_file.seek(80)
          @mesh_file.write([@face_count].pack('V'))
        end
        @mesh_file.close
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

      def self.options_dialog
        formats = %w(ASCII Binary)
        units   = ['Model Units', 'Meters', 'Centimeters', 'Millimeters', 'Inches', 'Feet']
        formats_translated = formats.map { |format| STL.translate(format) }
        units_translated   = units.map   { |unit| STL.translate(unit) }
        prompts  = [
          STL.translate('Export unit: '),
          STL.translate('File Format ')
        ]
        choices  = [
          units_translated.join('|'),
          formats_translated.join('|')
        ]
        defaults = [
          STL.translate(read_setting('export_units', 'Model Units')),
          STL.translate(read_setting('stl_format', 'ASCII'))
        ]
        title = STL.translate('STL Export Options')
        results = UI.inputbox(prompts, defaults, choices, title)
        return false if results == false
        if results[0] == STL.translate('Model Units')
          selected_units = model_units()
        else
          selected_units = results[0]
        end
        case selected_units
        when STL.translate('Meters')
          stl_conv = 0.0254
        when STL.translate('Centimeters')
          stl_conv = 2.54
        when STL.translate('Millimeters')
          stl_conv = 25.4
        when STL.translate('Feet')
          stl_conv = 0.0833333333333333
        when STL.translate('Inches')
          stl_conv = 1
        end
        #  Important to get the English value back from the format as the
        #  English string is expected and used for later processing of
        #  the options.
        #
        #  Also using the English unit name in the Registry.
        unit_index   = units_translated.index(results[0])
        write_setting('export_units', units[unit_index])

        format_index = formats_translated.index(results[1])
        write_setting('stl_format', formats[format_index])

        return [stl_conv, formats[format_index]]
      end # options_dialog()

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
            export_mesh_file
          }
        else
          item = UI.menu('File').add_item(STL.translate('Export STL...'), insert_index) {
            export_mesh_file
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
