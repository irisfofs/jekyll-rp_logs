require_relative "rp_log_converter"
require_relative "rp_parser"

module RpLogs

  class WeechatParser < RpLogs::Parser

    # Add this class to the parsing dictionary
    FORMAT_STR = 'weechat'
    RpLogGenerator.add self

    # Stuff
    class << self
      MODE = /([+%@&~!]?)/
      NICK = /([\w\-\\\[\]\{\}\^\`\|]+)/
      DATE_REGEXP = /(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)/

      FLAGS = /((?:![A-Z]+ )*)/
      JUNK =  /#{DATE_REGEXP}\t<?-->?\t.*$/
      EMOTE = /^#{FLAGS}#{DATE_REGEXP}\t \*\t#{NICK}\s+([^\n]*)$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP}\t#{MODE}#{NICK}\t([^\n]*)$/

      TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'

      def compile(logfile, options = {}) 
        compiled_lines = []

        logfile.each_line { |line| 
          case line
          when JUNK
            next
          when EMOTE
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            compiled_lines << Parser::LogLine.new(date, '', $3, $4, $1, :rp, options)
          when TEXT
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            mode = if $3 != '' then $3 else ' ' end
            compiled_lines << Parser::LogLine.new(date, mode, $4, $5, $1, :ooc, options)
          else
            # Only put text and emotes in the log
            next
          end
        }

        last_line = nil
        compiled_lines.reject! { |line| 
          if last_line == nil then
            last_line = line
            false
          elsif last_line.mergeable_with? line then
            last_line.merge! line
            # Delete the current line from output and maintain last_line 
            # in case we need to merge multiple times.
            true 
          else
            last_line = line
            false
          end
        }

        split_output = compiled_lines.map { |line| line.output }

        nicks = Set.new
        compiled_lines.each { |line| 
          nicks << line.sender if line.output_type == :rp
        }

        stats = { :nicks => nicks,
          :last_post_time => compiled_lines[-1].timestamp }

        [split_output.join("\n"), stats]
      end
    end

  end  

end
