# SketchUp to DXF STL Converter
# Last edited: February 18, 2011
# Authors: Nathan Bromham, Konrad Shroeder (http://www.guitar-list.com/)
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
module STL

def self.dxf_export_mesh_file
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
    dxf_dxf_units_dialog

    # Get DXF export option.
    dxf_option = dxf_dxf_options_dialog
    if (dxf_option =="stl")
      file_type="stl"
    else
      file_type="dxf"
    end

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
      dxf_header(dxf_option,model_name)

      # Recursively export faces and edges, exploding groups as we go.
      # Count "other" objects we can't parse.
      others = dxf_find_faces(0, export_ents, Geom::Transformation.new(), model.active_layer.name,dxf_option)
      dxf_end(dxf_option,model_name)
      UI.messagebox( @face_count.to_s + " facets exported " + @line_count.to_s + " lines exported\n" + others.to_s + " objects ignored" )
    end
  end
end

def self.dxf_find_faces(others, entities, tform, layername,dxf_option)
  entities.each do |entity|
    #Face entity
    if( entity.is_a?(Sketchup::Face) )
      case dxf_option
      when "polylines"
        dxf_write_polyline(entity,tform,layername)
      when "polyface mesh"
        dxf_write_polyface(entity,tform,layername)
      when "triangular mesh"
        dxf_write_face(entity,tform,layername)
      when "stl"
        dxf_write_stl(entity,tform)     
      end
      #Edge entity
    elsif( entity.is_a?(Sketchup::Edge)) and((dxf_option=="lines")or(entity.faces.length==0 and dxf_option!="stl"))
      dxf_write_edge(entity, tform, layername)
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
      others = dxf_find_faces(
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

def self.dxf_transform_edge(edge, tform)
  points=[]
  points.push(dxf_transform_vertex(edge.start, tform))
  points.push(dxf_transform_vertex(edge.end, tform))
  points
end

def self.dxf_transform_vertex(vertex, tform)
  point = Geom::Point3d.new(vertex.position.x, vertex.position.y, vertex.position.z)
  point.transform! tform
  point
end

def self.dxf_write_edge(edge, tform, layername)
  points = dxf_transform_edge(edge, tform)
  @mesh_file.puts( "  0\nLINE\n 8\n"+layername+"\n")
  for j in 0..1 do
    @mesh_file.puts((10+j).to_s+"\n"+(points[j].x.to_f * @stl_conv).to_s)#x
    @mesh_file.puts((20+j).to_s+"\n"+(points[j].y.to_f * @stl_conv).to_s)#y
    @mesh_file.puts((30+j).to_s+"\n"+(points[j].z.to_f * @stl_conv).to_s)#z
  end
  @line_count+=1
end

def self.dxf_write_polyline(face, tform,layername)
  face.loops.each do |aloop|
    @mesh_file.puts("  0\nPOLYLINE\n 8\n"+layername+"\n 66\n     1")
    @mesh_file.puts("70\n    8\n 10\n0.0\n 20\n 0.0\n 30\n0.0")
    for j in 0..aloop.vertices.length do
      if (j==aloop.vertices.length)
        count = 0
      else
        count = j
      end
      point = dxf_transform_vertex(aloop.vertices[count],tform)
      @mesh_file.puts( "  0\nVERTEX\n  8\nMY3DLAYER")
      @mesh_file.puts("10\n"+(point.x.to_f * @stl_conv).to_s)
      @mesh_file.puts("20\n"+(point.y.to_f * @stl_conv).to_s)
      @mesh_file.puts("30\n"+(point.z.to_f * @stl_conv).to_s)
      @mesh_file.puts( " 70\n     32")
    end
    if (aloop.vertices.length > 0)
      @mesh_file.puts( "  0\nSEQEND")
    end
  end
  @face_count+=1
end


def self.dxf_write_face(face,tform, layername)
  mesh = face.mesh 0
  mesh.transform! tform
  polygons = mesh.polygons
  polygons.each do |polygon|
    if (polygon.length > 2)
      flags = 0
      @mesh_file.puts( "  0\n3DFACE\n 8\n"+layername)
      for j in 0..polygon.length do
        if (j==polygon.length)
          count = polygon.length-1
        else
          count = j
        end
        #check edge visibility
        if ((polygon[count]<0))
          flags+=2**j
        end
        @mesh_file.puts((10+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).x.to_f * @stl_conv).to_s)
        @mesh_file.puts((20+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).y.to_f * @stl_conv).to_s)
        @mesh_file.puts((30+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).z.to_f * @stl_conv).to_s)
      end
      #edge visibiliy flags
      @mesh_file.puts("70\n"+flags.to_s)  
    end
  end
  @face_count+=1
end

def self.dxf_write_stl(face,tform)
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
        @mesh_file.write([norm.x].pack("e"))
        @mesh_file.write([norm.y].pack("e"))
        @mesh_file.write([norm.z].pack("e"))
      end
      for j in 0..2 do
        pt = mesh.point_at(polygon[j].abs)
        pt = pt.to_a.map{|e| e * @stl_conv}
        if @stl_type == "ascii"
          @mesh_file.puts("vertex #{pt.x} #{pt.y} #{pt.x}")
        else
          @mesh_file.write([pt.x].pack("e"))
          @mesh_file.write([pt.y].pack("e"))
          @mesh_file.write([pt.z].pack("e"))
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

def self.dxf_write_polyface(face,tform,layername)
  mesh = face.mesh 0
  mesh.transform! tform
  polygons = mesh.polygons
  points = mesh.points
  @mesh_file.puts("  0\nPOLYLINE\n 8\n"+layername+"\n 66\n     1")
  @mesh_file.puts("10\n0.0\n 20\n 0.0\n 30\n0.0\n")
  @mesh_file.puts("70\n    64\n") #flag for 3D polyface
  @mesh_file.puts("71\n"+mesh.count_points.to_s)
  @mesh_file.puts("72\n   1")
  #points
  points.each do |point| 
    @mesh_file.puts( "  0\nVERTEX\n  8\n"+layername)
    @mesh_file.puts("10\n"+(point.x.to_f * @stl_conv).to_s)
    @mesh_file.puts("20\n"+(point.y.to_f * @stl_conv).to_s)
    @mesh_file.puts("30\n"+(point.z.to_f * @stl_conv).to_s)
    @mesh_file.puts( " 70\n     192")
  end
  #polygons
  polygons.each do |polygon| 
    @mesh_file.puts( "  0\nVERTEX\n  8\n"+layername)
    @mesh_file.puts("10\n0.0\n 20\n 0.0\n 30\n0.0\n")
    @mesh_file.puts( " 70\n     128")
    @mesh_file.puts( " 71\n"+polygon[0].to_s)
    @mesh_file.puts( " 72\n"+polygon[1].to_s)
    @mesh_file.puts( " 73\n"+polygon[2].to_s)
    if (polygon.length==4)
      @mesh_file.puts( " 74\n"+polygon[3]..abs.to_s)
    end
  end
  @mesh_file.puts( "  0\nSEQEND")
  @face_count+=1
end

def self.dxf_dxf_options_dialog
  # Hardcoding for STL export for now.
  return "stl"

  options_list=["polyface mesh","polylines","triangular mesh","lines","stl"].join("|")
  prompts=["Export to DXF options"]
  enums=[options_list]
  values=["polyface mesh"]
  results = inputbox prompts, values, enums, "Choose which entities to export"
  return if not results
  results[0]
end

def self.stl_options_dialog
  prompts  = ["ASCII or Binary? "]
  defaults = ["Binary"]
  options  = ["ASCII|Binary"]
  UI.inputbox(prompts, defaults, options, "STL Type")
end

def self.dxf_dxf_units_dialog
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

def self.dxf_header(dxf_option,model_name)
  if (dxf_option=="stl")
    if @stl_type == "ascii"
      @mesh_file.puts( "solid " + model_name)
    else
      @mesh_file.write(["SketchUp STL #{model_name}"].pack("A80"))
      @mesh_file.write([0xffffffff].pack("V"))
    end
  else
    @mesh_file.puts( " 0\nSECTION\n 2\nENTITIES")
  end
end

def self.dxf_end(dxf_option,model_name)
  if (dxf_option=="stl")
    if @stl_type == "ascii"
      @mesh_file.puts( "endsolid " + model_name)
    else
      # binary - update facet count
      @mesh_file.flush
      @mesh_file.seek(80)
      @mesh_file.write([@face_count].pack("V"))
    end
  else
    @mesh_file.puts( " 0\nENDSEC\n 0\nEOF")
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
      dxf_export_mesh_file
    }
  else
    UI.menu('File').add_item('Export STL...', insert_index) {
      dxf_export_mesh_file
    }
  end
end

@sketchup_stl_loaded = true

end # module STL
end # module CommunityExtensions
