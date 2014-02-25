# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

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

  end # module STL
end # module CommunityExtensions
