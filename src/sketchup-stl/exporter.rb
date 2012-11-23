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

    def self.export_mesh_file
      model = Sketchup.active_model
      if model.active_entities.length == 0
        return UI.messagebox('Nothing to export.')
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
          'No objects selected. Export entire model?',
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
        out_name = UI.savepanel("#{file_type.upcase} file location", nil,
            "#{model_name}.#{file_type}")
        if out_name
          @mesh_file = File.new(out_name , 'w')  
          if @stl_type == STL_BINARY
            @mesh_file.binmode
          end
          write_header(model_name)

          # Recursively export faces and edges, exploding groups as we go.
          # Count "other" objects we can't parse.
          others = find_faces(0, export_ents, Geom::Transformation.new())
          write_footer(model_name)
          UI.messagebox("#{@face_count} facets exported\n#{others} objects" +
                        " ignored")
        end
      end
    end

    def self.find_faces(others, entities, tform)
      entities.each { |entity|
        #Face entity
        if entity.is_a?(Sketchup::Face)
          write_face(entity, tform)     
          #Group & Componentinstanceentity
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
      }
      others
    end

    def self.write_face(face, tform)
      mesh = face.mesh(7)
      mesh.transform!(tform)
      polygons = mesh.polygons
      polygons.each { |polygon|
        if polygon.length == 3
          norm = mesh.normal_at(polygon[0].abs)
          if @stl_type == STL_ASCII
            @mesh_file.puts("facet normal #{norm.x} #{norm.y} #{norm.z}")
            @mesh_file.puts('outer loop')
          else
            @mesh_file.write(norm.to_a.pack('e3'))
          end
          3.times { |j|
            pt = mesh.point_at(polygon[j].abs)
            pt = pt.to_a.map{ |e| e * @stl_conv }
            if @stl_type == STL_ASCII
              @mesh_file.puts("vertex #{pt.x} #{pt.y} #{pt.z}")
            else
              @mesh_file.write(pt.pack('e3'))
            end
          }
          if @stl_type == STL_ASCII
            @mesh_file.puts("endloop\nendfacet")
          else
            @mesh_file.write([0].pack('v'))
          end
        end
        @face_count += 1
      }
    end

    def self.write_header(model_name)
      if @stl_type == STL_ASCII
        @mesh_file.puts("solid #{model_name}")
      else
        @mesh_file.write(["SketchUp STL #{model_name}"].pack("A80"))
        @mesh_file.write([0xffffffff].pack('V'))
      end
    end

    def self.write_footer(model_name)
      if @stl_type == STL_ASCII
        @mesh_file.puts("endsolid #{model_name}")
      else
        # binary - update facet count
        @mesh_file.flush
        @mesh_file.seek(80)
        @mesh_file.write([@face_count].pack('V'))
      end
      @mesh_file.close
    end

    def self.options_dialog
      case Sketchup.active_model.options['UnitsOptions']['LengthUnit']
      when UNIT_METERS
        current_unit = 'Meters'
      when UNIT_CENTIMETERS
        current_unit = 'Centimeters'
      when UNIT_MILLIMETERS
        current_unit = 'Millimeters'
      when UNIT_FEET
        current_unit = 'Feet'
      when UNIT_INCHES
        current_unit = 'Inches'
      end
      units_list = %w(Meters Centimeters Millimeters Inches Feet).join('|')
      prompts  = ['Export unit: ', 'ASCII or Binary? ']
      choices  = [units_list, 'ASCII|Binary']
      defaults = [current_unit, 'Binary']
      results = UI.inputbox(prompts, defaults, choices, 'STL Export Options')
      return false if results == false
      case results[0]
      when 'Meters'
        stl_conv=0.0254
      when 'Centimeters'
        stl_conv=2.54
      when 'Millimeters'
        stl_conv=25.4
      when 'Feet'
        stl_conv=0.0833333333333333
      when 'Inches'
        stl_conv=1
      end
      return [stl_conv, results[1]]
    end

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
        UI.menu('File').add_item('Export STL...') {
          export_mesh_file
        }
      else
        UI.menu('File').add_item('Export STL...', insert_index) {
          export_mesh_file
        }
      end
      file_loaded(__FILE__)
    end

    end # module Exporter
  end # module STL
end # module CommunityExtensions
