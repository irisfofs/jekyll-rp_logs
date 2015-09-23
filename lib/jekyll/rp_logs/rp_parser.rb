module Jekyll
  module RpLogs

    class Parser
      FORMAT_STR = nil

      class LogLine
        MAX_SECONDS_BETWEEN_POSTS = 3
        RP_FLAG = "!RP"
        OOC_FLAG = "!OOC"
        MERGE_FLAG = "!MERGE"
        SPLIT_FLAG = "!SPLIT"

        attr :timestamp, :mode, :sender, :contents
        attr :flags
        # Some things depend on the original type of the line (nick format)
        attr :base_type
        attr :output_type
        attr :options

        attr :last_merged_timestamp

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

          # Check the contents for (
          @output_type = :ooc if @contents.strip[0] == "("

          # Flags override our assumptions, always
          if @flags.include? RP_FLAG
            @output_type = :rp
          elsif @flags.include? OOC_FLAG
            @output_type = :ooc
          end
          # TODO: Containing both flags should result in a warning
        end

        def output
          # String used for the timestamp anchors
          anchor = @timestamp.strftime("%Y-%m-%d_%H:%M:%S")
          # String used when hovering over timestamps (friendly long-form)
          title = @timestamp.strftime("%H:%M:%S %B %-d, %Y")
          # String actually displayed on page
          display = @timestamp.strftime("%H:%M")
          ts_out = "<a name=\"#{anchor}\" title=\"#{title}\" href=\"##{anchor}\">#{display}</a>"

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
          # The difference in time between the post merged into this one, and the next post, must be less than the limit
          close_enough_time = (next_line.timestamp - @last_merged_timestamp) * 24 * 60 * 60 <= MAX_SECONDS_BETWEEN_POSTS
          # Only merge posts with same sender
          same_sender = @sender == next_line.sender
          # Only merge rp lines
          is_rp = @output_type == :rp
          # Merge if next post is rp, or sender has split_to_normal_text property
          # Only merge if the base type was OOC... otherwise you couldn"t force not merging
          # Maybe a job for !NOTMERGE flag, or similar
          next_line_is_rp = next_line.output_type == :rp || \
            (@options[:merge_text_into_rp].include?(@sender) && next_line.base_type == :ooc)
          # Do not merge line if next line marked with !SPLIT
          split_flag = next_line.flags.include? SPLIT_FLAG
          # Merge if next line marked with !MERGE, regardless of other options
          merge_flag = next_line.flags.include? MERGE_FLAG

          merge_flag || (!split_flag && close_enough_time && same_sender && is_rp && next_line_is_rp)
        end

        def merge!(next_line)
          @contents += " " + next_line.contents
          @last_merged_timestamp = next_line.timestamp
        end

        def inspect
          "<#{@mode}#{@sender}> (#{@base_type} -> #{@output_type}) #{@content}"
        end
      end
    end

  end
end
