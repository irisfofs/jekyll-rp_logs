module Jekyll
  module RpLogs

    class WeechatParser < RpLogs::Parser

      # Add this class to the parsing dictionary
      FORMAT_STR = 'weechat'
      RpLogGenerator.add self

      # Stuff
      class << self
        # Regular expressions for chunks repeated in each type of message
        # (?<foo>pattern) is a named group, accessible via $~[:foo]
        MODE = /(?<mode>[+%@&~!]?)/
        NICK = /(?<nick>[\w\-\\\[\]\{\}\^\`\|]+)/
        DATE_REGEXP = /(?<timestamp>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)/

        FLAGS = /(?<flags>(?:![A-Z]+ )*)/

        # Regular expressions for matching each type of line
        JUNK =  /#{DATE_REGEXP}\t<?-->?\t.*$/
        EMOTE = /^#{FLAGS}#{DATE_REGEXP}\t \*\t#{NICK}\s+(?<msg>[^\n]*)$/
        TEXT  = /^#{FLAGS}#{DATE_REGEXP}\t#{MODE}#{NICK}\t(?<msg>[^\n]*)$/

        TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'

        def parse_line(line, options = {}) 
          case line
          when JUNK
            return nil
          when EMOTE
            date = DateTime.strptime($~[:timestamp], TIMESTAMP_FORMAT)
            return Parser::LogLine.new(date, options, sender: $~[:nick], \
              contents: $~[:msg], flags: $~[:flags], type: :rp)
          when TEXT
            date = DateTime.strptime($~[:timestamp], TIMESTAMP_FORMAT)
            $~[:mode] = ' ' if $~[:mode] == ''
            return Parser::LogLine.new(date, options, sender: $~[:nick], \
              contents: $~[:msg], flags: $~[:flags], type: :ooc, mode: $~[:mode])
          else
            # Only put text and emotes in the log
            return nil
          end
        end
      end

    end  

  end
end
