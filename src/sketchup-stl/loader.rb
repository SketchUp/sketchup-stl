# Copyright 2012 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0

require 'sketchup.rb'

module CommunityExtensions
  class STLImporter
  
    Sketchup::require File.join( PLUGIN_PATH, 'importer')
    Sketchup::require File.join( PLUGIN_PATH, 'exporter')

  end # class STLImporter
end # module CommunityExtensions
