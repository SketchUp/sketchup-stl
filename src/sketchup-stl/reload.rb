module TKS
  module SomePlugin

    if !defined?(@gui_loaded)

      # This assumes you have created a SketchupExtension object in a registrar
      # file in the "Plugins" folder, referenced by a local constant EXTENSION.
      UI.menu("Developer").add_item("Reload Code Files: sketchup_stl") {
        prev_dir = Dir.pwd
        Dir.chdir(__dir__) do
          Dir.glob("*.rb").each { |rb_file| load(rb_file) }
        rescue => error
          puts error.inspect
          puts error.backtrace
          Dir.chdir(prev_dir)
        end
      }

      @gui_loaded = true
    end

  end
end  