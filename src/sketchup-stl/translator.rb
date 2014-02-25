# Translator - the class formerly known as LanguageHandler2
#
# License: Apache License, Version 2.0

require 'sketchup'

module CommunityExtensions
  module STL

    # Class that handles string localizations.
    #
    # It is written to be able compatible with LanguageHandler which ships with
    # SketchUp (Current version 8M4). Existing .string files can be used and
    # methods are aliases so the class can be used as a drop in replacement.
    #
    # Strings must be placed in similar folder systems to SketchUp and the
    # naming of the folders much match what Sketchup.get_locale reports.
    #
    # Strings should be saved in UTF-8 encoded files, with or without BOM.
    #
    # Enhanced features include:
    # * One-line comments can start anywhere.
    # * Multi-line comments can start and stop anywhere outside a string.
    # * ; at the end of a key - value pair is optional.
    # * Strings can be split up by using the + operator.
    # * Strings can cross multiple lines.
    # * Strict enforcement of the format ensures an error is raised instead of
    #   producing junk data.
    # * Can be easily extended to include advanced features such as
    #   escape-characters if needed.
    #
    # See Tests folder for sample .strings files.
    #
    # Locales can be tested by starting SketchUp with the following arguments:
    #   sketchup.exe /lang de
    #
    # Note that there must exist a folder with that locale in the SketchUp
    # Resources folder.
    # https://github.com/SketchUp/sketchup-stl/issues/45#issuecomment-10819945
    class Translator

      STATE_SEARCH             =  0 # Looking for " or /
      STATE_IN_KEY             =  1 # Looking for "
      STATE_EXPECT_EQUAL       =  2 # Looking for =
      STATE_EXPECT_VALUE       =  3 # Looking for "
      STATE_IN_VALUE           =  4 # Looking for "
      STATE_EXPECT_END         =  5 # Looking for ;
      STATE_EXPECT_COMMENT     =  6 # Found / - Expecting * or / next
      STATE_IN_COMMENT_MULTI   =  7 # Found /* - Looking for */
      STATE_EXPECT_COMMENT_END =  8 # Found * - Expecting / next
      STATE_IN_COMMENT_SINGLE  =  9 # Found // - Looking for end of line
      STATE_EXPECT_UTF8_BOM    = 10 # Looking for UTF-8 BOM

      TOKEN_WHITESPACE     = /\s/
      TOKEN_CONCAT         = 43 # +
      TOKEN_QUOTE          = 34 # "
      TOKEN_EQUAL          = 61 # =
      TOKEN_END            = 59 # ;
      TOKEN_EOL            = /\n|\r/
      TOKEN_COMMENT_START  = 47 # /
      TOKEN_COMMENT_MULTI  = 42 # *
      TOKEN_COMMENT_SINGLE = 47 # /

      class ParseError < StandardError; end

      # A second optional Hash argument can be used to specify behaviour that
      # differ from LanguageHandler.
      #
      # Option Keys:
      # * :custom_path - String pointing to a custom path where the localized
      #                  strings are. If omitted the Translator will look in
      #                  SketchUp's Resource folder.
      # * :debug       - Set to true for a detailed trace of the parsing.
      #
      # @param [String] filename
      # @param [Nil,Hash] options
      def initialize(filename, options = nil)
        @path = nil
        @debug = false
        unless options.nil?
          unless options.is_a?(Hash)
            raise ArgumentError, 'Second argument must be Nil or a Hash.'
          end
          @path  = options[:custom_path] unless options[:custom_path].nil?
          @debug = options[:debug] unless options[:debug].nil?
        end
        @strings = parse(filename, @path)
      end

      # If the requested string is not in the localization dictionary then the
      # original string is returned.
      #
      # @param [String] string The String to be localized.
      #
      # @return [String] Localized string
      def get(string)
        @strings[string]
      end
      alias :GetString :get

      # @return [Hash] The dictionary Hash used for localization.
      def dictionary
        @strings
      end
      alias :GetStrings :dictionary

      # @param [String] custom_path
      #
      # @return [String]
      def self.GetResourceSubPath(custom_path = nil)
        if custom_path
          full_file_path = File.join(custom_path, Sketchup.get_locale)
        else
          full_file_path = Sketchup.get_resource_path('')
        end
        components = full_file_path.split(File::SEPARATOR)
        components[-2, 2].join(File::SEPARATOR)
      end

      # Prints out the dictionary for visual inspection.
      #
      # @return [String]
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

      # @return [String]
      def inspect
        object_hex_id = "0x%x" % (self.object_id << 1)
        size = @strings.size
        locale = Sketchup.get_locale
        "<#{self.class}::#{object_hex_id} - Strings:#{size} (#{locale})>"
      end

      private

      # Parses the given file and returns a Hash lookup.
      #
      # @param [String] filename
      # @param [String] custom_path
      #
      # @return [Hash]
      def parse(filename, custom_path = nil)
        # Find the correct file based on the current locale setting in SketchUp.
        # If no path has been given it'll revert back to the Resource folder in
        # SketchUp, like LanguageHandler does.
        if custom_path
          path = File.expand_path(custom_path)
          full_file_path = File.join(path, Sketchup.get_locale, filename)
        else
          full_file_path = Sketchup.get_resource_path(filename)
        end

        # Define returned dictionary. Make a hash that will return the key given
        # if the key doesn't exist. That way, when a translation is missing for
        # a string it will be returned un-translated.
        strings = Hash.new { |hash, key| key }

        # Ensure the file is valid.
        if full_file_path.nil? || !File.exist?(full_file_path)
          puts "Warning! Could not load dictionary: #{full_file_path}"
          return strings
        end

        # Read and process the content.
        state = STATE_SEARCH
        key_buffer = ''
        value_buffer = ''
        state_cache = nil # Used when comments are exited.

        # File position statistics.
        last_line_break = nil
        line_pos = 0

        if Sketchup.version.split('.')[0].to_i < 14
          read_flags = 'r'
        else
          read_flags = 'r:BOM|UTF-8'
        end

        File.open(full_file_path, read_flags) { |file|
          file.lineno = 1 # Line numbers must be manually tracked.
          file.each_byte { |byte|
            # Count line numbers and keep track of line position.
            if byte.chr =~ TOKEN_EOL # (?) Can we avoid regex? Is 10 & 13 enough?
              line_pos = 0
              if last_line_break.nil? || byte == last_line_break
                file.lineno += 1
                last_line_break = byte
              end
            else
              line_pos += 1
              last_line_break = nil
            end

            log_state(state, byte)

            # Check for UTF-8 BOM at the beginning of the file. (0xEF,0xBB,0xBF)
            # This is done here before the rest of the parsing as these are
            # special bytes that doesn't appear visible in editors.
            if file.lineno == 1
              if line_pos == 1 && byte == 0xEF
                state = STATE_EXPECT_UTF8_BOM
                next
              elsif state == STATE_EXPECT_UTF8_BOM
                if line_pos == 2 && byte == 0xBB
                  next
                elsif line_pos == 3 && byte == 0xBF
                  # Reset line position tracker as the BOM is not visible in
                  # editors and will give misleading references.
                  line_pos = 0
                  state = STATE_SEARCH
                  next
                end
                raise ParseError, parse_error(file, state, byte, line_pos)
              end
            end

            # Process the current byte.
            # Note that White-space and EOL matches are done with regex and
            # therefore last in evaluation.
            case state

            # Neutral state looking for the beginning of a key or comment.
            when STATE_SEARCH
              if byte == TOKEN_QUOTE
                state = STATE_IN_KEY
              elsif byte == TOKEN_COMMENT_START
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end

            # Parser is inside a key string looking for end-quote.
            # All characters that are not the end-quote is considered part of
            # the string and is added to the buffer.
            when STATE_IN_KEY
              if byte == TOKEN_QUOTE
                state = STATE_EXPECT_EQUAL
              else
                key_buffer << byte
              end

            # After a key the parser expects to find an equal token or a concat
            # token that will allow a string to be split up. Comments are
            # allowed.
            when STATE_EXPECT_EQUAL
              # Accept: Whitespace, Comment
              # Look for: = /
              if byte == TOKEN_EQUAL
                state = STATE_EXPECT_VALUE
              elsif byte == TOKEN_CONCAT
                state = STATE_SEARCH
              elsif byte == TOKEN_COMMENT_START
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end

            # After a key and equal-token is found the parser expects to find
            # a value string. Comments are allowed.
            when STATE_EXPECT_VALUE
              if byte == TOKEN_QUOTE
                state = STATE_IN_VALUE
              elsif byte == TOKEN_COMMENT_START
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end

            # Parser is inside a value string looking for end-quote.
            # All characters that are not the end-quote is considered part of
            # the string and is added to the buffer.
            when STATE_IN_VALUE
              if byte == TOKEN_QUOTE
                state = STATE_EXPECT_END
                strings[ key_buffer ] = value_buffer
              else
                value_buffer << byte
              end

            # After a key and value pair has been found the parser expects to
            # find and end token or end of line. The end token is only required
            # if multiple statements are placed on the same line.
            #
            # A concat token will kick the parser back into looking for a value
            # string.
            #
            # Comments are allowed.
            when STATE_EXPECT_END
              if byte == TOKEN_END || byte.chr =~ TOKEN_EOL
                state = STATE_SEARCH
                key_buffer = ''
                value_buffer = ''
              elsif byte == TOKEN_CONCAT
                state = STATE_EXPECT_VALUE
              elsif byte == TOKEN_COMMENT_START
                state_cache = state
                state = STATE_EXPECT_COMMENT
              elsif byte.chr =~ TOKEN_WHITESPACE
                # Ignore.
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end

            # The beginning of a comment is found. The next token is expected to
            # be a token for either singe-line or multi-line comment.
            when STATE_EXPECT_COMMENT
              if byte == TOKEN_COMMENT_MULTI
                state = STATE_IN_COMMENT_MULTI
              elsif byte == TOKEN_COMMENT_SINGLE
                state = STATE_IN_COMMENT_SINGLE
              else
                raise ParseError, parse_error(file, state, byte, line_pos)
              end

            # The parser is processing a multi-line comment. When it encounter a
            # multi-line token will look for an comment end-token next. All
            # other data is ignored.
            when STATE_IN_COMMENT_MULTI
              if byte == TOKEN_COMMENT_MULTI # Multiline Comment
                state = STATE_EXPECT_COMMENT_END
              end

            # The parser is processing a multi-line comment and the last token
            # was an indication for end of comment. If this token is not an
            # end-token it will resume to processing the comment.
            when STATE_EXPECT_COMMENT_END
              if byte == TOKEN_COMMENT_START # End token is the same as start.
                state = state_cache
              elsif byte != TOKEN_COMMENT_MULTI
                state = STATE_IN_COMMENT_MULTI
              end

            # The parser is processing a single-line comment. The comment ends
            # at the first end-of-line.
            when STATE_IN_COMMENT_SINGLE
              if byte.chr =~ TOKEN_EOL
                state = state_cache
              end
            end
          } # file.each_byte
        } # File.open

        return strings
      end
      alias :ParseLangFile :parse

      # Converts a state code into a readable string. For debugging and error
      # messages.
      #
      # @param [Integer] state
      #
      # @return [String]
      def state_to_string(state)
        {
          STATE_SEARCH              => 'STATE_SEARCH',
          STATE_IN_KEY              => 'STATE_IN_KEY',
          STATE_EXPECT_EQUAL        => 'STATE_EXPECT_EQUAL',
          STATE_EXPECT_VALUE        => 'STATE_EXPECT_VALUE',
          STATE_IN_VALUE            => 'STATE_IN_VALUE',
          STATE_EXPECT_END          => 'STATE_EXPECT_END',
          STATE_EXPECT_COMMENT      => 'STATE_EXPECT_COMMENT',
          STATE_IN_COMMENT_MULTI    => 'STATE_IN_COMMENT_MULTI',
          STATE_EXPECT_COMMENT_END  => 'STATE_EXPECT_COMMENT_END',
          STATE_IN_COMMENT_SINGLE   => 'STATE_IN_COMMENT_SINGLE',
          STATE_EXPECT_UTF8_BOM     => 'STATE_EXPECT_UTF8_BOM'
        }[state]
      end

      # Prints out the current state of the parser if debugging is enabled.
      # Slows down the process a lot when enabled - but gives detailed insight
      # to what the parser is doing.
      #
      # @param [Integer] state
      # @param [Integer] byte
      #
      # @return [Nil]
      def log_state(state, byte)
        return nil unless @debug
        token = if byte == TOKEN_QUOTE
          'TOKEN_QUOTE'
        elsif byte == TOKEN_EQUAL
          'TOKEN_EQUAL'
        elsif byte == TOKEN_END
          'TOKEN_END'
        elsif byte == TOKEN_COMMENT_START
          'TOKEN_COMMENT_START'
        elsif byte == TOKEN_COMMENT_MULTI
          'TOKEN_COMMENT_MULTI'
        elsif byte == TOKEN_COMMENT_SINGLE
          'TOKEN_COMMENT_SINGLE'
        elsif byte.chr =~ TOKEN_WHITESPACE
          'TOKEN_WHITESPACE'
        elsif byte.chr =~ TOKEN_EOL
          'TOKEN_EOL'
        else
          'TOKEN_NEUTRAL'
        end
        puts "#{state_to_string(state)}\n #{token} (#{byte})"
        nil
      end

      # Generates a formatted string with debug info - used when a ParseError
      # is raised.
      #
      # @param [File] file The File object being parsed.
      # @param [Integer] state The state of the parser.
      # @param [Integer] byte The current byte being read.
      # @param [Integer] line_pos The current position on the current line.
      #
      # @return [String]
      def parse_error(file, state, byte, line_pos)
        "#{state_to_string(state)} - " <<
        "Unexpected token: #{byte.chr} (#{byte}) " <<
        "on line #{file.lineno}:#{line_pos}"
      end

    end # class Translator

  end # module STL
end # module CommunityExtensions
