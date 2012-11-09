# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl

require 'sketchup.rb'
require 'extensions.rb'

module CommunityExtensions
  module STL
  
    PLUGIN_ROOT_PATH = File.dirname(__FILE__)
    PLUGIN_PATH = File.join(PLUGIN_ROOT_PATH, 'sketchup-stl')
  
    extension = SketchupExtension.new(
      'STL Import & Export',
      File.join( PLUGIN_PATH, 'loader.rb')
    )

    extension.description = 'Adds STL file format import and export. ' <<
      'This is an open source project sponsored by the SketchUp team. More ' <<
      'info and updates at https://github.com/SketchUp/sketchup-stl'
    extension.version = '1.0.0'
    extension.copyright = '2012 Trimble Navigation, released under Apache 2.0'
    extension.creator = 'J. Foltz, N. Bromham, K. Shroeder, SketchUp Team'
        
    Sketchup.register_extension( extension, true )
    
  end # module STL
end # module CommunityExtensions
