# SketchUp to DXF STL Converter
# Last edited: February 18, 2011
# Authors: Nathan Bromham, Konrad Shroeder (http://www.guitar-list.com/)
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
  module STL
    module Exporter

    def self.export_mesh_file
      model = Sketchup.active_model
      if model.active_entities.length == 0
        return UI.messagebox("Nothing to export.")
      end
      model_filename = File.basename(model.path)
      if model_filename == ""
        model_filename = "model"
      end
      @stl_conv = 1.0
      @face_count = 0
      @line_count = 0
      ss = model.selection
      if ss.empty?
        answer = UI.messagebox("No objects selected. Export entire model?",
                               MB_YESNOCANCEL)
        if answer == IDYES
          export_ents = model.entities
        else
          export_ents = ss
        end
      else
        export_ents = Sketchup.active_model.selection
      end
      if (export_ents.length > 0)
        # Get units for export.
        units_dialog()

        # Get DXF export option.
        file_type="stl"

        options = stl_options_dialog
        return if options == false
        @stl_type = options[0].downcase

        # Get exported file name and export.
        out_name = UI.savepanel("#{file_type.upcase} file location", "" ,
            "#{File.basename(model.path).split(".")[0]}untitled." +file_type)
        if out_name
          @mesh_file = File.new( out_name , "w" )  
          if @stl_type != "ascii"
            @mesh_file.binmode
          end
          model_name = model_filename.split(".")[0]
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
      entities.each do |entity|
        #Face entity
        if entity.is_a?(Sketchup::Face)
          write_face(entity,tform)     
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
      end
      others
    end

    def self.write_face(face, tform)
      mesh = face.mesh 7
      mesh.transform! tform
      polygons = mesh.polygons
      polygons.each do |polygon|
        if (polygon.length == 3)
          norm = mesh.normal_at(polygon[0].abs)
          if @stl_type == "ascii"
            @mesh_file.puts("facet normal #{norm.x} #{norm.y} #{norm.z}")
            @mesh_file.puts("outer loop")
          else
            @mesh_file.write(norm.to_a.pack("e3"))
          end
          for j in 0..2 do
            pt = mesh.point_at(polygon[j].abs)
            pt = pt.to_a.map{|e| e * @stl_conv}
            if @stl_type == "ascii"
              @mesh_file.puts("vertex #{pt.x} #{pt.y} #{pt.z}")
            else
              @mesh_file.write(pt.pack("e3"))
            end
          end
          if @stl_type == "ascii"
            @mesh_file.puts( "endloop\nendfacet")
          else
            @mesh_file.write([0].pack("v"))
          end
        end
        @face_count+=1
      end
    end

    def self.write_header(model_name)
      if @stl_type == "ascii"
        @mesh_file.puts( "solid " + model_name)
      else
        @mesh_file.write(["SketchUp STL #{model_name}"].pack("A80"))
        @mesh_file.write([0xffffffff].pack("V"))
      end
    end

    def self.write_footer(model_name)
      if @stl_type == "ascii"
        @mesh_file.puts( "endsolid " + model_name)
      else
        # binary - update facet count
        @mesh_file.flush
        @mesh_file.seek(80)
        @mesh_file.write([@face_count].pack("V"))
      end
      @mesh_file.close
    end

    def self.stl_options_dialog
      prompts  = ["ASCII or Binary? "]
      choices  = ["ASCII|Binary"]
      defaults = ["Binary"]
      UI.inputbox(prompts, defaults, choices, "STL Type")
    end

    def self.units_dialog
      # Hardcoding for millimeters export for now.
      @stl_conv = 25.4
      return

      cu=Sketchup.active_model.options[0]["LengthUnit"]
      case cu
      when 4
        current_unit= "Meters"
      when 3
        current_unit= "Centimeters"
      when 2
        current_unit= "Millimeters"
      when 1
        current_unit= "Feet"
      when 0
        current_unit= "Inches"
      end
      units_list=["Meters","Centimeters","Millimeters","Inches","Feet"].join("|")
      prompts=["Export unit: "]
      enums=[units_list]
      values=[current_unit]
      results = inputbox prompts, values, enums, "Export units"
      return if not results
      case results[0]
      when "Meters"
        @stl_conv=0.0254
      when "Centimeters"
        @stl_conv=2.54
      when "Millimeters"
        @stl_conv=25.4
      when "Feet"
        @stl_conv=0.0833333333333333
      when "Inches"
        @stl_conv=1
      end
    end

    if( not @sketchup_stl_loaded )
      IS_MAC = ( Object::RUBY_PLATFORM =~ /darwin/i ? true : false )
      # Pick menu indexes for where to insert the Export menu. These numbers
      # where picked when SketchUp 8 M4 was the latest version.
      if IS_MAC
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
    end

    @sketchup_stl_loaded = true

    end # module Exporter
  end # module STL
end # module CommunityExtensions
