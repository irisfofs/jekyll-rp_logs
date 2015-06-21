module Jekyll
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

        def parse_line(line, options = {}) 
          case line
          when JUNK
            return nil
          when EMOTE
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            return Parser::LogLine.new(date, options, sender: $3, contents: $4, \
              flags: $1, type: :rp)
          when TEXT
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            mode = if $3 != '' then $3 else ' ' end
            return Parser::LogLine.new(date, options, sender: $4, contents: $5, \
              flags: $1, type: :ooc, mode: mode)
          else
            # Only put text and emotes in the log
            return nil
          end
        end
      end

    end  

  end
end
