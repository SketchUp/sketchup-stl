# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl

require 'sketchup.rb'
require 'extensions.rb'

su_stl_extension = SketchupExtension.new 'STL Import/Export',
    'sketchup-stl/loader.rb'

su_stl_extension.description = 'Adds STL file format import and export. ' +
    'This is an open source project sponsored by the SketchUp team. More ' +
    'info and updates at https://github.com/SketchUp/sketchup-stl'
su_stl_extension.version = '1.0.0'
su_stl_extension.copyright = '2012 Trimble Navigation, released under Apache 2.0'
su_stl_extension.creator = 'J. Foltz, N. Bromham, K. Shroeder, ' +
    'SketchUp Team'

Sketchup.register_extension su_stl_extension, true
