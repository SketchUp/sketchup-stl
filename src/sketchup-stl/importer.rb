# jf_stl_importer.rb - Imports ascii and binary .stl file in SketchUp
#
# Copyright (C) 2010 Jim Foltz (jim.foltz@gmail.com)
#
# License: Apache License, Version 2.0

require 'sketchup'

module CommunityExtensions
  module STL
    class Importer

      Sketchup::require File.join(PLUGIN_PATH, 'webdialog_extensions')

      PREF_KEY = 'CommunityExtensions\STL\Importer'.freeze
      
      IMPORT_SUCCESS                        = 0
      IMPORT_FAILED                         = 1
      IMPORT_CANCELLED                      = 2
      IMPORT_FILE_NOT_FOUND                 = 4
      IMPORT_SKETCHUP_VERSION_NOT_SUPPORTED = 5

      def initialize
        @stl_units = UNIT_MILLIMETERS
        @stl_merge = false
        @stl_preserve_origin = true

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

      def load_file(path,status)
        begin
          status = main(path)
        rescue Exception => e
          puts e.message
          puts e.backtrace.join("\n")
          status = IMPORT_FAILED
        end
        return status
      end

      def main(filename)
        file_type = detect_file_type(filename)
        #p file_type
        # Read import settings.
        @stl_merge           = read_setting('merge_faces',     @stl_merge)
        @stl_units           = read_setting('import_units',    @stl_units)
        @stl_preserve_origin = read_setting('preserve_origin', @stl_preserve_origin)
        # Wrap everything into one operation, ensuring compatibility with older
        # SketchUp versions that did not feature the disable_ui argument.
        model = Sketchup.active_model
        if model.method(:start_operation).arity == 1
          model.start_operation(STL.string('STL Import'))
        else
          model.start_operation(STL.string('STL Import'), true)
        end
        # Import geometry.
        Sketchup.status_text = STL.string('Importing geometry...')
        if file_type[/solid/]
          entities = stl_ascii_import(filename)
        else
          entities = stl_binary_import(filename)
        end
        return IMPORT_CANCELLED if entities == IMPORT_CANCELLED
        # Verify that anything was imported.
        if entities.nil? || entities.length == 0
          model.abort_operation
          UI.messagebox(STL.string('No geometry was imported.')) if entities
          Sketchup.status_text = '' # OSX doesn't reset the statusbar like Windows.
          return IMPORT_FAILED
        end
        # Reposition to ORIGIN.
        group = entities.parent.instances[0]
        unless @stl_preserve_origin
          point = group.bounds.corner(0)
          vector = point.vector_to(ORIGIN)
          group.transform!(vector) if vector.valid?
        end
        # Check if the imported geometry is a solid. If not, attempt to
        # automatically repair it.
        unless is_solid?(group)
          Sketchup.status_text = STL.string('Repairing geometry...')
          heal_geometry(entities)
        end
        # Focus camera on imported geometry.
        model.active_view.zoom(group)
        # Clean up geometry.
        if @stl_merge
          Sketchup.status_text = STL.string('Cleaning up geometry...')
          cleanup_geometry(entities)
        end
        Sketchup.status_text = STL.string('Importing STL done!')
        model.commit_operation
        return IMPORT_SUCCESS
      end
      private :main

      def detect_file_type(file)
        first_line = File.open(file, 'r') { |f| f.read(80) }
        return first_line
      end
      private :detect_file_type

      def do_msg(msg)
        return UI.messagebox(msg, MB_YESNO)
      end
      private :do_msg

      def stl_binary_import(filename, try = 1)
        stl_conv = get_unit_ratio(@stl_units)
        f = File.new(filename, 'rb')
        # Header
        header = ''
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
        msg = STL.string("STL Importer (c) Jim Foltz\n\nSTL Binary Header:\n%s\n\nFound %i triangles. Continue?")
        msg = sprintf(msg, header, len)
        if do_msg(msg) == IDNO
          f.close
          return IMPORT_CANCELLED
        end

        pts = []
        while !f.eof 
          normal = f.read(3 * float_size).unpack('fff')
          v1 = f.read(3 * float_size).unpack('fff') 
          v1.map!{|e| e * stl_conv}
          v2 = f.read(3 * float_size).unpack('fff')
          v2.map!{|e| e * stl_conv}
          v3 = f.read(3 * float_size).unpack('fff')
          v3.map!{|e| e * stl_conv}
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
        return entities
      end
      private :stl_binary_import

      def stl_ascii_import(filename, try = 1)
        stl_conv = get_unit_ratio(@stl_units)
        polys = []
        poly = []
        vcnt = 0
        IO.foreach(filename) do |line|
          line.chomp!
          if line[/vertex/]
            vcnt += 1
            c, *pts = line.split
            pts.map! { |pt| pt.to_f * stl_conv }
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
        msg = STL.string("STL Importer (c) Jim Foltz\n\nSTL ASCII File\nFound %i polygons.\n\nContinue?")
        msg = sprintf(msg, polys.length)
        if do_msg(msg) == IDNO
          return IMPORT_CANCELLED
        end
        mesh = Geom::PolygonMesh.new(3 * polys.length, polys.length)
        polys.each{ |poly| mesh.add_polygon(poly) }
        entities = Sketchup.active_model.entities
        if entities.length > 0
          grp = entities.add_group
          entities = grp.entities
        end
        st = entities.fill_from_mesh(mesh, false, 0)
        return entities
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
        # Since WebDialogs under OSX isn't truly modal wthere is a chance the user
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
          :dialog_title     => STL.string('Import STL Options'),
          :preferences_key  => false,
          :scrollable       => false,
          :resizable        => false,
          :left             => 300,
          :top              => 200,
          :width            => 350, # 315,
          :height           => 265
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
          # Ensure they are in proper format. (Recovers from old settings)
          merge_faces     = ( merge_faces == true )
          current_unit    = current_unit.to_i
          preserve_origin = ( preserve_origin == true )
          # Update webdialog values.
          dialog.update_value('chkMergeCoplanar', merge_faces)
          dialog.update_value('lstUnits', current_unit)
          dialog.update_value('chkPreserveOrigin', preserve_origin)
          # Localize UI
          dialog.update_text({
            '#geometry legend' => STL.string('Geometry'),
            '#merge_coplanar span' => STL.string('Merge coplanar faces'),
            
            '#scale legend' => STL.string('Scale'),
            '#units span' => STL.string('Units:'),
            '#lstUnits option[value="4"]' => STL.string('Meters'),
            '#lstUnits option[value="3"]' => STL.string('Centimeters'),
            '#lstUnits option[value="2"]' => STL.string('Millimeters'),
            '#lstUnits option[value="1"]' => STL.string('Feet'),
            '#lstUnits option[value="0"]' => STL.string('Inches'),
            '#preserve_origin span' => STL.string('Preserve drawing origin'),
            
            '#btnAccept' => STL.string('Accept'),
            '#btnCancel' => STL.string('Cancel')
          })
        }

        window.add_action_callback('Event_Accept') { |dialog, params|
          # Get data from webdialog.
          options = {
            :merge_coplanar   => dialog.get_element_value('chkMergeCoplanar'),
            :units            => dialog.get_element_value('lstUnits'),
            :preserve_origin  => dialog.get_element_value('chkPreserveOrigin')
          }
          dialog.close
          #p options # DEBUG
          # Convert to Ruby values.
          @stl_merge            = (options[:merge_coplanar] == 'true')
          @stl_preserve_origin  = (options[:preserve_origin] == 'true')
          @stl_units            = options[:units].to_i
          # Store last used preferences.
          write_setting('merge_faces',     @stl_merge)
          write_setting('import_units',    @stl_units)
          write_setting('preserve_origin', @stl_preserve_origin)
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

      # Cleans up the geometry in the given +entities+ collection.
      #
      # @param [Sketchup::Entities] entities
      # 
      # @return [Nil]
      def cleanup_geometry(entities)
        stack = entities.select { |e| e.is_a?(Sketchup::Edge) }
        until stack.empty?
          edge = stack.shift
          next unless edge.valid?
          next unless edge.faces.length == 2
          face1, face2 = edge.faces
          # Check if all the points of the two faces are on the same plane.
          # Comparing normals is not enough.
          next unless face1.normal.samedirection?(face2.normal)
          pts1 = face1.vertices.map { |vertex| vertex.position }
          pts2 = face2.vertices.map { |vertex| vertex.position }
          points = pts1 + pts2
          plane = Geom.fit_plane_to_points(points)
          next unless points.all? { |point| point.on_plane?(plane) }
          # In CleanUp the faces are checked to not be duplicate of each other -
          # overlapping. But since can we assume the STL importer doesn't create
          # such messy geometry?
          # 
          # There is also a routine in CleanUp omitted here that checks if the
          # faces to be merged are degenerate - all edges are parallel.
          # 
          # These check have been omitted to save processing time - as they might
          # not appear in a STL import? The checks where required in CleanUp due
          # to the large amount of degenerate geometry it was fed.
          # 
          # 
          # Erasing the shared edges is tricky. Often things get messed up if we
          # try to erase them all at once. When colouring the result of
          # shared_edges it appear that edges between non-planar faces are
          # returned. Not sure why this is.
          # 
          # What does seem to work best is to first erase the edge we got from the
          # stack and then check the shared set of edges afterwards and erase them
          # after we've verified they are not part of any faces anymore.
          shared_edges = face1.edges & face2.edges
          #shared_edges.each { |e| e.material = 'red' } # DEBUG
          edge.erase!
          # Find left over edges that are no longer connected to any face.
          loose_edges = shared_edges.select { |e| e.valid? && e.faces.empty? }
          entities.erase_entities(loose_edges)
          # Validate result - check if we destroyed some geometry.
          if face1.deleted? && face2.deleted?
            puts 'Merge error!' # DEBUG. What should be do there?
          end
        end
        nil
      end
      private :cleanup_geometry
      
      # This function is ported from Vertex Tools. It attempts to trigger
      # SketchUp's own healing mechanism.
      #
      # I have tried two versions of this method, one where there is one temp
      # group and edge for each vertex, and one (this one) where there is only
      # one temp group. This latter one is three times faster than the former.
      # However, when testing Vertex Tools there appeared to be some edge cases
      # where this one didn't fix everything.
      # Those cases where very extreme cases of messed up geometry, so I chose
      # to still use this one due to its performance.
      #
      # Should there be a number of cases where healing is required and this
      # method doesn't cut it, then it can be replaced with the alternative
      # version. But until we have a set of real world cases I want to use this
      # one. 
      #
      # -ThomThom
      #
      # @param [Sketchup::Entities] entities
      # @param [Array<Geom::Point3d>] points
      #
      # @return [Integer]
      # @since 1.1.0
      def heal_geometry(entities)
        # Collect positions of all vertices.
        vertices = entities.grep(Sketchup::Edge) { |edge|
          edge.vertices
        }
        vertices.flatten!
        vertices.uniq!
        points = vertices.map! { |vertex| vertex.position }
        # Heal vertices.
        # Create a temp group with a set of zero length edges for each vertex -
        # when exploded will trigger SketchUp's internal healing function.
        temp_group = entities.add_group
        offset_reverse = Z_AXIS.reverse
        vertices = []
        vectors = []
        for point in points
          temp_edge = temp_group.entities.add_line(point, point.offset(Z_AXIS))
          vertices << temp_edge.end
          vectors  << offset_reverse
        end
        temp_group.entities.transform_by_vectors(vertices, vectors)
        temp_group.explode
        points.size
      end
      private :heal_geometry
      
      # Checks of a given instance contains geometry that is solid. Compatible
      # with older SketchUp versions before SketchUp 8.
      #
      # @param [Sketchup::Group,Sketchup::ComponentInstance] instance
      def is_solid?(instance)
        if instance.respond_to?(:manifold?) 
          instance.manifold?
        else
          retrofit_manifold?(instance)
        end
      end
      private :is_solid?
      
      # Fallback method for checking if an instance is solid for versions older
      # older than SketchUp 8.
      #
      # @param [Sketchup::Group,Sketchup::ComponentInstance] instance
      def retrofit_manifold?(instance)
        if instance.is_a?(Sketchup::Group)
          definition = instance.entities.parent
        else
          definition = instance.definition
        end
        # (i) Since we know the instance has been populated with a PolygonMesh
        #     we know there won't be any sub-groups/components or any other
        #     entities we have to test for.
        definition.entities.grep(Sketchup::Edge) { |edge|
          return false unless edge.faces.length == 2
        }
        true
      end
      private :retrofit_manifold?

    end # class Importer

  end # module STL
end # module CommunityExtensions

unless file_loaded?(__FILE__)
  Sketchup.register_importer(CommunityExtensions::STL::Importer.new)
  file_loaded(__FILE__)
end
