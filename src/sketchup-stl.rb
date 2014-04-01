# Copyright 2012-2014 Trimble Navigation Ltd.
#
# License: Apache License, Version 2.0
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl

require 'sketchup.rb'
require 'extensions.rb'

module CommunityExtensions
  module STL
      # Load SKUI lib
      load File.join(File.dirname(__FILE__), 'sketchup-stl', 'SKUI',
       'embed_skui.rb')
      ::SKUI.embed_in(self)

    PLUGIN_ROOT_PATH    = File.dirname(__FILE__)
    PLUGIN_PATH         = File.join(PLUGIN_ROOT_PATH, 'sketchup-stl')
    PLUGIN_STRINGS_PATH = File.join(PLUGIN_PATH, 'strings')

    Sketchup::require File.join(PLUGIN_PATH, 'translator')
    options = {
      :custom_path => PLUGIN_STRINGS_PATH,
      :debug => false
    }
    @translator = Translator.new('STL.strings', options)

    # Method for easy access to the translator instance to anything within this
    # project.
    #
    # @example
    #   STL.translate('Hello World')
    def self.translate(string)
      @translator.get(string)
    end

    extension = SketchupExtension.new(
      STL.translate('STL Import & Export'),
      File.join(PLUGIN_PATH, 'loader.rb')
    )

    extension.description = STL.translate(
      'Adds STL file format import and export. ' <<
      'This is an open source project sponsored by the SketchUp team. More ' <<
      'info and updates at https://github.com/SketchUp/sketchup-stl'
    )
    extension.version = '2.1.3'
    extension.copyright = '2012-2014 Trimble Navigation, ' <<
      'released under Apache 2.0'
    extension.creator = 'J. Foltz, N. Bromham, K. Shroeder, SketchUp Team'

    Sketchup.register_extension(extension, true)

  end # module STL
end # module CommunityExtensions
