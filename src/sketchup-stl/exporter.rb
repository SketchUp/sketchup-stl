# SketchUp to DXF STL Converter
# Last edited: February 18, 2011
# Authors: Nathan Bromham, Konrad Shroeder (http://www.guitar-list.com/)
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
  module STL

    def self.export_mesh_file
      model = Sketchup.active_model
      model_filename = File.basename(model.path)
      if( model_filename == "" )
        model_filename = "model"
      end
      ss = model.selection
      @stl_conv = 1.0
      @face_count = 0
      @line_count = 0
      if ss.empty?
        answer = UI.messagebox("No objects selected. Export entire model?", MB_YESNOCANCEL)
        if( answer == 6 )
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
        dxf_option = "stl"
        file_type="stl"

        options = stl_options_dialog
        return if options == false
        @stl_type = options[0].downcase

        # Get exported file name and export.
        out_name = UI.savepanel( file_type.upcase + " file location", "" , "#{File.basename(model.path).split(".")[0]}untitled." +file_type )
        if out_name
          @mesh_file = File.new( out_name , "w" )  
          if @stl_type != "ascii"
            @mesh_file.binmode
          end
          model_name = model_filename.split(".")[0]
          write_header(model_name)

          # Recursively export faces and edges, exploding groups as we go.
          # Count "other" objects we can't parse.
          others = find_faces(0, export_ents, Geom::Transformation.new(), model.active_layer.name,dxf_option)
          write_footer(model_name)
          UI.messagebox( @face_count.to_s + " facets exported " + @line_count.to_s + " lines exported\n" + others.to_s + " objects ignored" )
        end
      end
    end

    def self.find_faces(others, entities, tform, layername,dxf_option)
      entities.each do |entity|
        #Face entity
        if( entity.is_a?(Sketchup::Face) )
          write_face(entity,tform)     
          #Group & Componentinstanceentity
        elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          # I don't quite understand what the organization intention of the original
          # code was in terms of working out the layer name. Appear to be based on
          # object name... The old code name an incremental name prefixed GROUP or
          # COMPONENT which didn't make any sense at all. And it modified the entity
          # name.
          # 
          # At the moment I just make it take either the instance name or definition
          # name. But I wonder if there's a more sensible name to use for this.
          # 
          # (!) This layername argument should be looked into further. But for now I
          #     just wanted to avoid the exporter making model changes.
          # 
          # -ThomThom
          if entity.is_a?(Sketchup::Group)
            # (!) Beware - Due to a SketchUp bug this can be incorrect. Fix later.
            definition = entity.entities.parent
          else
            definition = entity.definition
          end
          layer = ( entity.name.empty? ) ? definition.name : entity.name
          others = find_faces(
            others,
            definition.entities,
            tform * entity.transformation,
            layer,
            dxf_option
          )
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
            @mesh_file.write([norm.x, norm.y, norm.z].pack("e3"))
          end
          for j in 0..2 do
            pt = mesh.point_at(polygon[j].abs)
            pt = pt.to_a.map{|e| e * @stl_conv}
            if @stl_type == "ascii"
              @mesh_file.puts("vertex #{pt.x} #{pt.y} #{pt.x}")
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

    if( not @sketchup_stl_loaded )
      IS_MAC = ( Object::RUBY_PLATFORM =~ /darwin/i ? true : false )
      # Pick menu indexes for where to insert the Export menu. These numbers where
      # picked when SketchUp 8 M4 was the latest version.
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

  end # module STL
end # module CommunityExtensions
