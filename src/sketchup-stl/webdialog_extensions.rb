# Copyright 2012-2015 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl
#
# WebDialog Extensions

require 'sketchup'

module CommunityExtensions
  module STL


    # Helper module to ease some of the communication with WebDialogs.
    # Extend the WebDialog instance or include it in a subclass.
    #
    # Instance Extend:
    #
    #   window = UI::WebDialog.new(window_options)
    #   window.extend( WebDialogExtensions )
    #   # ...
    #
    # Sub-class include:
    #
    #   class CustomWindow << UI::WebDialog
    #     include WebDialogExtensions
    #     # ...
    #   end
    module WebDialogExtensions

      # Wrapper that makes calling JavaScript functions cleaner and easier. A very
      # simplified version of the wrapper used in TT::GUI::Window.
      #
      # `function` is a string with the JavaScript function name.
      #
      # The remaining arguments are optional and will be passed to the function.
      def call_function(function, *args)
        # Just a simple conversion, which ensures strings are escaped.
        arguments = args.map { |value|
          if value.is_a?(Hash)
            hash_to_json(value)
          else
            value.inspect
          end
        }.join(',')
        function = "#{function}(#{arguments});"
        execute_script(function)
      end

      # (i) Assumes the WebDialog HTML includes `base.js`.
      #
      # Updates the form value of the given element. Use the id attribute of the
      # form element - without the `#` prefix.
      def update_value(element_id, value)
        call_function('UI.update_value', element_id, value)
      end

      # (i) Assumes the WebDialog HTML includes `base.js`.
      #
      # Updates the text of the given jQuery selector matches.
      def update_text(hash)
        call_function('UI.update_text', hash)
      end

      # Returns a JavaScript JSON object for the given Ruby Hash.
      def hash_to_json(hash)
        data = hash.map { |key, value| "#{key.inspect}: #{value.inspect}" }
        "{#{data.join(',')}}"
      end

      def parse_params(params)
        params.split('|||')
      end

    end # module WebDialogBridge

  end # module STL
end # module CommunityExtensions
