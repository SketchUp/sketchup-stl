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
      # The remaining arguments are optionol and will be passed to the function.
      def call_function(function, *args)
        # Just a simple conversion, which ensures strings are escaped.
        arguments = args.map { |value| value.inspect}.join(',')
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

    end # module WebDialogBridge

  end # module STL
end # module CommunityExtensions
