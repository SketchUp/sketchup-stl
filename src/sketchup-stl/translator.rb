# 
#
# License: Apache License, Version 2.0

require 'sketchup'

module CommunityExtensions
  module STL
    class Translator
      
      STATE_SEARCH             = 0 # Looking for " or /
      STATE_IN_KEY             = 1 # Looking for "
      STATE_EXPECT_EQUAL       = 2 # Looking for =
      STATE_EXPECT_VALUE       = 3 # Looking for "
      STATE_IN_VALUE           = 4 # Looking for "
      STATE_EXPECT_END         = 5 # Looking for ;
      STATE_EXPECT_COMMENT     = 6 # Found / - Expecting * or / next
      STATE_IN_COMMENT         = 7 # Found /* - Looking for */
      STATE_EXPECT_COMMENT_END = 8 # Found * - Expecting / next
      STATE_EXPECT_EOL         = 9 # Found // - Looking for end of line
      
      TOKEN_WHITESPACE = /\s/
      TOKEN_QUOTE      = ?"
      TOKEN_EQUAL      = ?=
      TOKEN_END        = ?;
      TOKEN_EOL        = /\n|\r/
      TOKEN_COMMENT    = ?/
      TOKEN_ML_COMMENT = ?*
      
      class ParseError < StandardError; end

      def initialize(filename, options = nil)
        @path = nil
        @debug = false
        unless options.nil?
          unless options.is_a?(Hash)
            raise ArgumentError, 'Second argument must be Nil or a Hash.'
          end
          @path  = options[:custom_path]
          @debug = options[:debug]
        end
        @strings = parse(filename, @path)
      end
      
      def get(key)
        @strings[key]
      end
      alias :GetString :get

      def dictionary
        @strings
      end
      alias :GetStrings :dictionary

      def self.GetResourceSubPath(custom_path = nil)
        if custom_path
          full_file_path = File.join(custom_path, Sketchup.get_locale)
        else
          full_file_path = Sketchup.get_resource_path('')
        end
        components = full_file_path.split(File::SEPARATOR)
        components[-2, 2].join(File::SEPARATOR)
      end
      
      def print_dictionary
        output = ''
        for key, value in @strings
          output << "====================\n"
          output << "#{key}\n"
          output << "--------------------\n"
          output << "#{value}\n"
        end
        puts output
      end
      
      def inspect
        object_hex_id = "0x%x" % (self.object_id << 1)
        size = @strings.size
        locale = Sketchup.get_locale
        "<#{self.class}::#{object_hex_id} - Strings:#{size} (#{locale})>"
      end
      
      private
      
      def parse(filename, custom_path = nil)
        # Find the correct file based on the current locale setting in SketchUp.
        # If no path has been given it'll revert back to the Resource folder in
        # SketchUp, like LanguageHandler does.
        if custom_path
          full_file_path = File.join(custom_path, Sketchup.get_locale, filename)
        else
          full_file_path = Sketchup.get_resource_path(filename)
        end
        
        # Ensure the file is valid.
        if full_file_path.nil? || !File.exist?(full_file_path)
          raise ArgumentError, "Invalid file! #{full_file_path}"
        end
        
        # Define returned dictionary. Make a hash that will return the key given
        # if the key doesn't exist. That way, when a translation is missing for
        # a string it will be returned un-translated.
        strings = Hash.new { |hash, key| key }
        
        # Read and process the content.
        state = STATE_SEARCH
        key_buffer = ''
        value_buffer = ''
        state_cache = nil # Used when comments are exited.
        
        # File position statistics.
        last_line_break = nil
        line_pos = 1
        
        File.open(full_file_path, 'r') { |file|
          file.lineno = 1
          file.each_byte { |byte|
            # Count line numbers and keep track of line position.
            if byte.chr =~ TOKEN_EOL
              line_pos = 0
              if last_line_break.nil? || byte == last_line_break
                file.lineno += 1
                last_line_break = byte
              end
            else
              line_pos += 1
              last_line_break = nil
            end
            
            # Process the current byte.
            log_state(state, byte)
            case state
            when STATE_SEARCH
              # Accept: Whitespace, Comment
              # Look for: " /
              if byte == TOKEN_QUOTE
                state = STATE_IN_KEY
                key_buffer = ''
              elsif byte == TOKEN_COMMENT
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            when STATE_IN_KEY
              # Look for: "
              if byte == TOKEN_QUOTE
                state = STATE_EXPECT_EQUAL
              else
                key_buffer << byte
              end
            when STATE_EXPECT_EQUAL
              # Accept: Whitespace, Comment
              # Look for: = /
              if byte == TOKEN_EQUAL
                state = STATE_EXPECT_VALUE
              elsif byte == TOKEN_COMMENT
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            when STATE_EXPECT_VALUE
              # Accept: Whitespace
              # Look for: " /
              if byte == TOKEN_QUOTE
                state = STATE_IN_VALUE
                value_buffer = ''
              elsif byte == TOKEN_COMMENT
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            when STATE_IN_VALUE
              # Look for: "
              if byte == TOKEN_QUOTE
                state = STATE_EXPECT_END
                strings[ key_buffer ] = value_buffer
              else
                value_buffer << byte
              end
            when STATE_EXPECT_END
              # Accept: Whitespace, Comment
              # Look for: ; /
              if byte == TOKEN_END
                state = STATE_SEARCH
              elsif byte == TOKEN_COMMENT
                state_cache = state
                state = STATE_EXPECT_COMMENT
              # (i) Enable this rule to accept EOL as substitute for ;
              elsif byte.chr =~ TOKEN_EOL
                state = STATE_SEARCH
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            when STATE_EXPECT_COMMENT
              # Look for: / *
              if byte == TOKEN_ML_COMMENT # Multiline Comment
                state = STATE_IN_COMMENT
              elsif byte == TOKEN_COMMENT # Single Line Comment
                state = STATE_EXPECT_EOL
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            when STATE_IN_COMMENT
              # Look for: *
              if byte == TOKEN_ML_COMMENT # Multiline Comment
                state = STATE_EXPECT_COMMENT_END
              end
            when STATE_EXPECT_COMMENT_END
              # Look for: /
              if byte == TOKEN_COMMENT
                state = state_cache
              end
            when STATE_EXPECT_EOL
              # Look for: \n \r
              if byte.chr =~ TOKEN_EOL
                state = state_cache
              end
            end
          } # file.each_byte
        } # File.open

        return strings
      end
      alias :ParseLangFile :parse
      
      def state_to_string(state)
        {
          STATE_SEARCH              => 'STATE_SEARCH',
          STATE_IN_KEY              => 'STATE_IN_KEY',
          STATE_EXPECT_EQUAL        => 'STATE_EXPECT_EQUAL',
          STATE_EXPECT_VALUE        => 'STATE_EXPECT_VALUE',
          STATE_IN_VALUE            => 'STATE_IN_VALUE',
          STATE_EXPECT_END          => 'STATE_EXPECT_END',
          STATE_EXPECT_COMMENT      => 'STATE_EXPECT_COMMENT',
          STATE_IN_COMMENT          => 'STATE_IN_COMMENT',
          STATE_EXPECT_COMMENT_END  => 'STATE_EXPECT_COMMENT_END',
          STATE_EXPECT_EOL          => 'STATE_EXPECT_EOL'
        }[state]
      end
      
      def log_state(state, byte)
        return nil unless @debug
        token = if byte == TOKEN_QUOTE
          'TOKEN_QUOTE'
        elsif byte == TOKEN_EQUAL
          'TOKEN_EQUAL'
        elsif byte == TOKEN_END
          'TOKEN_END'
        elsif byte == TOKEN_COMMENT
          'TOKEN_COMMENT'
        elsif byte == TOKEN_ML_COMMENT
          'TOKEN_ML_COMMENT'
        elsif byte.chr =~ TOKEN_WHITESPACE
          'TOKEN_WHITESPACE'
        elsif byte.chr =~ TOKEN_EOL
          'TOKEN_EOL'
        else
          'TOKEN_NEUTRAL'
        end
        puts "#{state_to_string(state)}\n #{token} (#{byte})"
      end
      
      def parse_error(file, state, byte, line_pos)
        "#{state_to_string(state)} - " <<
        "Unexpected token: #{byte.chr} (#{byte}) " <<
        "on line #{file.lineno}:#{line_pos}"
      end

    end # class Translator
  end # module STL
end # module CommunityExtensions