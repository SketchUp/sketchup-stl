module SKUI
  # @since 1.0.0
  module Debug

    @enabled = false

    # @since 1.0.0
    def self.enabled?
      @enabled == true
    end

    # @since 1.0.0
    def self.enabled=( value )
      @enabled = ( value ) ? true : false
    end

    # @since 1.0.0
    def self.puts( *args )
      p *args if @enabled
    end

    # SKUI::Debug.list_objects
    #
    # @return [Nil]
    # @since 1.0.0
    def self.list_objects
      keys = [
        UI::WebDialog,
        Window,
        Base,
        Control,
        Button,
        Checkbox,
        Container,
        Groupbox,
        Image,
        Label,
        Listbox,
        RadioButton,
        Textbox,
        Bridge,
        Font,
        JSON,
        Rect
      ]
      values = keys.map { |klass|
        ObjectSpace.each_object( klass ) {}
      }
      references = Hash[*keys.zip(values).flatten]

      Kernel.puts ""
      Kernel.puts "============================================================"
      Kernel.puts " ObjectSpace References"
      Kernel.puts "============================================================"
      for klass, count in references
        Kernel.puts " #{klass.to_s.ljust(20)} : #{count}"
      end
      Kernel.puts "============================================================"
      Kernel.puts ""
      nil
    end

  end # class
end # module