module CommunityExtensions
  module STL
    module Utils

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
          # overlapping. But can we assume the STL importer doesn't create
          # such messy geometry?
          # 
          # There is also a routine in CleanUp omitted here that checks if the
          # faces to be merged are degenerate - all edges are parallel.
          # 
          # These check have been omitted to save processing time - as they might
          # not appear in a STL import? The checks were required in CleanUp due
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
          # after we've verified they are not part of any faces any more.
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
        offset_reverse = [Z_AXIS.reverse]
        for point in points
          temp_edge = temp_group.entities.add_line(point, point.offset(Z_AXIS))
          # To prevent the temp edges to merging with each other they must be
          # transformed to zero length edges immediately after creation.
          # See Issue #77.
          temp_group.entities.transform_by_vectors(
            [temp_edge.end], offset_reverse)
        end
        temp_group.explode
        points.size
      end
      private :heal_geometry

      # Checks of a given instance contains geometry that is solid. Compatible
      # with older SketchUp versions before SketchUp 8.
      #
      # @param [Sketchup::Group,Sketchup::ComponentInstance] instance
      def is_solid?(entities)
        entities.grep(Sketchup::Edge) { |edge|
          return false if edge.faces.length != 2
        }
        return true
      end
      private :is_solid?

      # Returns the definition for a +Group+, +ComponentInstance+ or +Image+
      #
      # @param [:definition, Sketchup::Group, Sketchup::Image] instance
      #
      # @return [Sketchup::ComponentDefinition,Mixed]
      def self.definition(instance)
        if instance.respond_to?(:definition)
          return instance.definition
        elsif instance.is_a?(Sketchup::Group)
          # (i) group.entities.parent should return the definition of a group.
          # But because of a SketchUp bug we must verify that group.entities.parent
          # returns the correct definition. If the returned definition doesn't
          # include our group instance then we must search through all the
          # definitions to locate it.
          if instance.entities.parent.instances.include?(instance)
            return instance.entities.parent
          else
            Sketchup.active_model.definitions.each { |definition|
              return definition if definition.instances.include?(instance)
            }
          end
        elsif instance.is_a?(Sketchup::Image)
          Sketchup.active_model.definitions.each { |definition|
            if definition.image? && definition.instances.include?(instance)
              return definition
            end
          }
        end
        return nil # Given entity was not an instance of an definition.
      end

    end # Utils
  end # STL
end # CommunityExtensions
