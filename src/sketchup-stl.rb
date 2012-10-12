# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0

require 'sketchup.rb'
require 'extensions.rb'

su_stl_extension = SketchupExtension.new 'STL Import/Export',
    'sketchup-stl/loader.rb'

su_stl_extension.description = 'Adds STL file format import and export.'
su_stl_extension.version = '1.0'
su_stl_extension.copyright = '2012 Trimble Navigation Ltd.'
su_stl_extension.creator = 'Jim Foltz, Nathan Bromham, Konrad Shroeder, ' +
    'and members of the SketchUp team'

Sketchup.register_extension su_stl_extension, true
