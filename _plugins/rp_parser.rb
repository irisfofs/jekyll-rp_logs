module RpLogs

  class Parser
    FORMAT_STR = nil

    class LogLine
      MAX_SECONDS_BETWEEN_POSTS = 3
      RP_FLAG = '!RP'
      OOC_FLAG = '!OOC'

      attr :timestamp, :mode, :sender, :contents
      attr :flags
      # Some things depend on the original type of the line (nick format)
      attr :base_type
      attr :output_type
      attr :options

      def initialize(timestamp, options = {}, sender:, contents:, flags:, type:, mode: ' ') 
        @timestamp = timestamp
        @mode = mode
        @sender = sender
        @contents = contents
        @flags = flags.split(' ')

        @base_type = type
        @output_type = type

        @options = options

        # This makes it RP by default
        @output_type = :rp if options[:strict_ooc]

        # Check the contents for (
        @output_type = :ooc if contents.strip[0] == '('
        
        # Flags override our assumptions, always
        if flags.include? RP_FLAG then
          @output_type = :rp
        elsif flags.include? OOC_FLAG then
          @output_type = :ooc
        end
      end

      def output
        anchor = @timestamp.strftime('%Y-%m-%d_%H:%M:%S')
        ts_out = "<a name=\"#{anchor}\" href=\"##{anchor}\">#{@timestamp.strftime('%H:%M')}</a>"

        sender_out = nil
        case @base_type
        when :rp
          sender_out = "  * #{@sender}"
        when :ooc
          sender_out = " &lt;#{@mode}#{@sender}&gt;"
        else
          # Explode.
          throw "No known type: #{@base_type}"
        end

        tag_class = nil
        tag_close = "</p>"
        case @output_type
        when :rp 
          tag_class = "rp"
        when :ooc
          tag_class = "ooc"
        else
          # Explode.
          throw "No known type: #{@output_type}"
        end
        tag_open = "<p class=\"#{tag_class}\">"

        "#{tag_open}#{ts_out}#{sender_out} #{@contents}#{tag_close}"
      end

      def mergeable_with?(next_line)
        # Only merge posts close enough in time
        close_enough_time = next_line.timestamp - @timestamp <= MAX_SECONDS_BETWEEN_POSTS
        # Only merge posts with same sender
        same_sender = @sender == next_line.sender
        # Only merge rp lines
        is_rp = @output_type == :rp
        # Merge if next post is rp, or sender has split_to_normal_text property
        # Only merge if the base type was OOC... otherwise you couldn't force not merging
        # Maybe a job for !NOTMERGE flag, or similar
        next_line_is_rp = next_line.output_type == :rp || \
          (@options[:merge_text_into_rp].include?(@sender) && next_line.base_type == :ooc)

        close_enough_time && same_sender && is_rp && next_line_is_rp
      end

      def merge!(next_line)
        # How to handle content..
        @contents += ' ' + next_line.contents
      end
    end
  end

end
