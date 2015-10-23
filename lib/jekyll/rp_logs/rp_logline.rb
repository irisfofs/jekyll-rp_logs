require "cgi"

module Jekyll
  module RpLogs
    class LogLine
      RP_FLAG = "!RP".freeze
      OOC_FLAG = "!OOC".freeze
      MERGE_FLAG = "!MERGE".freeze
      SPLIT_FLAG = "!SPLIT".freeze

      attr_reader :timestamp, :mode, :sender, :contents, :flags
      # Some things depend on the original type of the line (nick format)
      attr_reader :base_type, :output_type
      attr_reader :options

      # Timestamp of the most recent line this line was merged with, to allow
      # merging consecutive lines each MAX_SECONDS_BETWEEN_POSTS apart
      attr_reader :last_merged_timestamp

      # The max number of seconds between two lines that can still be merged
      @max_seconds_between_posts = 3

      # All characters that can denote the beginning of an OOC line
      @ooc_start_delimiters = "([".freeze

      class << self
        attr_reader :ooc_start_delimiters, :max_seconds_between_posts

        def extract_settings(config)
          @max_seconds_between_posts = config.fetch("max_seconds_between_posts",
                                                    @max_seconds_between_posts)
          @ooc_start_delimiters = config.fetch("ooc_start_delimiters",
                                               @ooc_start_delimiters).freeze
        end
      end

      def initialize(timestamp, options = {}, sender:, contents:, flags:, type:, mode: " ")
        @timestamp = timestamp
        # Initialize to be the same as @timestamp
        @last_merged_timestamp = timestamp
        @mode = mode
        @sender = sender
        @contents = contents
        @flags = flags.split(" ")

        @base_type = type
        @output_type = type

        @options = options

        classify
      end

      ##
      # Set derived properties of this LogLine based on various options
      def classify
        # This makes it RP by default
        @output_type = :rp if @options[:strict_ooc]

        # Check the contents for leading ( or [
        @output_type = :ooc if ooc_start_delimiters.include? @contents.strip[0]

        # Flags override our assumptions, always
        if @flags.include? RP_FLAG
          @output_type = :rp
        elsif @flags.include? OOC_FLAG
          @output_type = :ooc
        end
        # TODO: Containing both flags should result in a warning
      end

      def output
        tag_open, tag_close = output_tags
        # Escape any HTML special characters in the input
        escaped_content = CGI.escapeHTML(@contents)
        "#{tag_open}#{output_timestamp}#{output_sender} #{escaped_content}#{tag_close}"
      end

      def output_timestamp
        # String used for the timestamp anchors
        anchor = @timestamp.strftime("%Y-%m-%d_%H:%M:%S")
        # String used when hovering over timestamps (friendly long-form)
        title = @timestamp.strftime("%H:%M:%S %B %-d, %Y")
        # String actually displayed on page
        display = @timestamp.strftime("%H:%M")
        "<a name=\"#{anchor}\" title=\"#{title}\" href=\"##{anchor}\">#{display}</a>"
      end

      def output_sender
        case @base_type
        when :rp
          return "  * #{@sender}"
        when :ooc
          return " &lt;#{@mode}#{@sender}&gt;"
        else
          # Explode.
          fail "No known type: #{@base_type}"
        end
      end

      def output_tags
        tag_class =
          case @output_type
          when :rp then "rp"
          when :ooc then "ooc"
          else # Explode.
            fail "No known type: #{@output_type}"
          end
        tag_open = "<p class=\"#{tag_class}\">"
        tag_close = "</p>"

        [tag_open, tag_close]
      end

      ##
      # Check if this line can be merged with the given line. In order to be
      # merged, the two lines must fulfill the following requirements:
      #
      # * The timestamp difference is >= 0 and <= MAX_SECONDS_BETWEEN POSTS
      #   (close_enough_timestamps?)
      # * The lines have the same sender (same_sender?)
      # * The first line has output_type :rp (rp?)
      # * The next line has output_type :rp OR the sender has been specified
      #   as someone who splits to normal text
      #
      # Exceptions:
      # * If the next line has the SPLIT flag, it will never be merged
      # * If the next line has the MERGE flag, it will always be merged
      def mergeable_with?(next_line)
        # Perform the checks for the override flags
        return true if next_line.merge_flag?
        return false if next_line.split_flag?
        mergeable_ignoring_flags?(next_line)
      end

      ##
      # Does all the rest of the checks that don't have to do with the
      # override flags SPLIT_FLAG and MERGE_FLAG.
      private def mergeable_ignoring_flags?(next_line)
        close_enough_timestamps?(next_line) &&
          same_sender?(next_line) &&
          rp? &&
          (next_line.rp? || next_line.possible_split_to_normal_text?)
      end

      def merge!(next_line)
        @contents += "#{space_between_lines}#{next_line.contents}"
        @last_merged_timestamp = next_line.timestamp
        self
      end

      ##
      # Returns "" if the sender has been said to split by characters.
      # Returns " " otherwise.
      #
      # When the sender splits by characters, adding a space will put spaces in
      # the middle of words. Their spaces will be preserved at the end of lines.
      private def space_between_lines
        if options[:splits_by_character] &&
           options[:splits_by_character].include?(@sender)
          ""
        else
          " "
        end
      end

      def inspect
        "<#{@mode}#{@sender}> (#{@base_type} -> #{@output_type}) #{@contents}"
      end

      ##
      # Returns true if this line has the output_type :rp
      def rp?
        @output_type == :rp
      end

      def split_flag?
        @flags.include? SPLIT_FLAG
      end

      def merge_flag?
        @flags.include? MERGE_FLAG
      end

      ##
      # Return true if this sender splits to normal text, and the line base
      # type was OOC. This allows you to force a quick text post not to merge
      # by flagging it !OOC.
      #
      # Only merge if the base type was OOC... otherwise you couldn't force not merging
      # Maybe a job for !NOTMERGE flag, or similar
      protected def possible_split_to_normal_text?
        base_type == :ooc && @options[:merge_text_into_rp] &&
          @options[:merge_text_into_rp].include?(@sender)
      end

      private

      ##
      # Only merge posts close enough in time
      # The difference in time between the post merged into this one, and
      # the next post, must be less than the limit (and non-negative)
      def close_enough_timestamps?(next_line)
        time_diff = (next_line.timestamp - @last_merged_timestamp) * 24 * 60 * 60
        time_diff >= 0 && time_diff <= max_seconds_between_posts
      end

      ##
      # Returns if these lines have the same sender
      def same_sender?(next_line)
        @sender == next_line.sender
      end

      def max_seconds_between_posts
        self.class.max_seconds_between_posts
      end

      def ooc_start_delimiters
        self.class.ooc_start_delimiters
      end
    end
  end
end
