# jf_stl_importer.rb - Imports ascii and binary .stl file in SketchUp
#
# Copyright (C) 2010 Jim Foltz (jim.foltz@gmail.com)
#
# License: Apache License, Version 2.0

require 'sketchup'

module JF
    class STLImporter

        def initialize
            @stl_conv = 1
        end

        def description
            "STL Importer (*.stl) by Jim Foltz"
        end
        def id
            "jim.foltz@gmail.com/stl_importer"
        end
        def file_extension
            "stl"
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
            rescue Exception=>e
                puts e.message
                puts e.backtrace
            end
            r = 1
            r = 0 if status == true
            return r
        end

        def main(filename)
            file_type = detect_file_type(filename)
            #p file_type
            if file_type[/solid/]
                stl_ascii_import(filename)
            else
                stl_binary_import(filename)
            end
        end
        private :main

        def get_filename
            filename = UI.openpanel("Open STL File", nil, "*.stl;*.stlb")
        end
        private :get_filename

        def detect_file_type(file)
            first_line = File.open(file, 'r') { |f| f.read(80) }
            return(first_line)
        end
        private :detect_file_type

        def do_msg(msg)
            return( UI.messagebox(msg, MB_YESNO) )
        end
        private :do_msg

        def stl_binary_import(filename, try = 1)
            f = File.new(filename, "rb")
            # Header
            header = ""
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
            msg =  "STL Importer (c) Jim Foltz\n\nSTL Binary Header:\n"+header+"\n\nFound #{ len.inspect } triangles. Continue?"
            if do_msg(msg) == IDNO
                f.close
                return
            end

            pts = []
            while !f.eof 
                normal = f.read(3 * float_size).unpack('fff')
                v1 = f.read(3 * float_size).unpack('fff') 
                v1.map!{|e| e * @stl_conv}
                v2 = f.read(3 * float_size).unpack('fff')
                v2.map!{|e| e * @stl_conv}
                v3 = f.read(3 * float_size).unpack('fff')
                v3.map!{|e| e * @stl_conv}
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
            return st
        end
        private :stl_binary_import

        def stl_ascii_import(filename, try = 1)
            polys = []
            poly = []
            vcnt = 0
            IO.foreach(filename) do |line|
                line.chomp!
                if line[/vertex/]
                    vcnt += 1
                    c, *pts = line.split
                    pts.map! { |pt| pt.to_f * @stl_conv }
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
            msg = "STL Importer (c) Jim Foltz\n\nSTL ASCII File\nFound #{polys.length} polygons.\n\nContinue?"
            if do_msg(msg) == IDNO
                return
            end
            Sketchup.active_model.start_operation "STL Import", true
            mesh = Geom::PolygonMesh.new 3*polys.length, polys.length
            polys.each{ |poly| mesh.add_polygon(poly) }
            entities = Sketchup.active_model.entities
            if entities.length > 0
                grp = entities.add_group
                entities = grp.entities
            end
            st = entities.fill_from_mesh(mesh, false, 0)
            Sketchup.active_model.commit_operation
            return st
        end

        def stl_dialog
            current_unit = Sketchup.read_default("JFSTLImporter", 'import_units')
            if current_unit.nil?
                cu=Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
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
            end
            units_list=["Meters","Centimeters","Millimeters","Inches","Feet"].join("|")
            prompts=["Import Units "]
            enums=[units_list]
            values=[current_unit]
            results = inputbox prompts, values, enums, "JF STL Importer"
            return if not results
            mu = units_list.split('|')
            cu = mu.index(results[0])
            case cu
            when 0
                @stl_conv = 100.0 / 2.54
            when 1
                @stl_conv = 1.0 / 2.54
            when 2
                @stl_conv = 0.1 / 2.54
            when 3
                @stl_conv = 12.0
            when 4
                @stl_conv = 1
            end
            Sketchup.write_default("JFSTLImporter", 'import_units', results[0])
        end
        private :stl_dialog

    end # module STLImporter

end # module JF

Sketchup.register_importer(JF::STLImporter.new)
