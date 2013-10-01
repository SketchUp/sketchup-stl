module SKUI

  require File.join( PATH, 'checkbox.rb' )


  # @since 1.0.0
  class RadioButton < Checkbox

    # @return [RadioButton]
    # @since 1.0.0
    def checked_sibling
      siblings.find { |radio_button| radio_button.checked? }
    end

    # @return [Array<RadioButton>]
    # @since 1.0.0
    def siblings
      parent.controls.grep( RadioButton )
    end

  end # class
end # module