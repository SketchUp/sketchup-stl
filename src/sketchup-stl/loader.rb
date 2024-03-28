# Copyright 2012-2015 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl
#
# Loader

require 'sketchup'

module CommunityExtensions
  module STL

    IS_OSX = ( Object::RUBY_PLATFORM =~ /darwin/i ? true : false )

    # Matches Sketchup.active_model.options['UnitsOptions']['LengthUnit']
    UNIT_METERS      = 4
    UNIT_CENTIMETERS = 3
    UNIT_MILLIMETERS = 2
    UNIT_FEET        = 1
    UNIT_INCHES      = 0

    Sketchup::require File.join(PLUGIN_PATH, 'utils')
    Sketchup::require File.join(PLUGIN_PATH, 'importer')
    Sketchup::require File.join(PLUGIN_PATH, 'exporter')
    # Sketchup::require File.join(PLUGIN_PATH, 'reload')

  end # module STL
end # module CommunityExtensions
