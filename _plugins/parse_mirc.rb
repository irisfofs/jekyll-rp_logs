require_relative "rp_log_converter"
require_relative "rp_parser"

module RpLogs

  class MIRCParser < RpLogs::Parser

    # Add this class to the parsing dictionary
    FORMAT_STR = 'MIRC'
    RpLogGenerator.add self

    # Stuff
    class << self
      MODE = /([+%@&~!]?)/
      NICK = /([\w\-\\\[\]\{\}\^\`\|]+)/
      DATE_REGEXP = /(\d\d \d\d \d\d\[\d\d:\d\d\])/ #Remember to change this for your date format
	  #For example, this regex is for, mm dd yy[HH:nn] or 06 14 15[18:48]

      FLAGS = /((?:![A-Z]+ )*)/
	  # Crappy but works
	  # The ()?((?=\d{4})(\d\d))? bit of code is to remove the  and two random numbers in front of lines. 
	  #This assumes that you have a two digit date code stating your time stamp.
	  USER_AT_HOST = /\(\w+@[^)]+\)/
	  JUNK = /()?((?=\d{4})(\d\d))?#{DATE_REGEXP} \* #{MODE}#{NICK} (sets mode:|is now known as|(#{USER_AT_HOST} (has joined|Quit|has left))).*$/
      EMOTE = /^#{FLAGS}()?((?=\d{4})(\d\d))?#{DATE_REGEXP}\s\*\s#{MODE}#{NICK}\s+([^\n]*)$/
      TEXT  = /^#{FLAGS}()?((?=\d{4})(\d\d))?#{DATE_REGEXP}\s<#{MODE}#{NICK}>\s([^\n]*)$/

      TIMESTAMP_FORMAT = '%m %d %y[%H:%M]'

      def parse_line(line, options = {}) 
        case line
        when JUNK
          nil
        when EMOTE
          date = DateTime.strptime($5, TIMESTAMP_FORMAT)
          Parser::LogLine.new(date, options, sender: $7, contents: $8, \
            flags: $1, type: :rp)
        when TEXT
          date = DateTime.strptime($5, TIMESTAMP_FORMAT)
          mode = if $6 != '' then $6 else ' ' end
          Parser::LogLine.new(date, options, sender: $7, contents: $8, \
            flags: $1, type: :ooc, mode: mode)
        else
          # Only put text and emotes in the log
          nil
        end
      end
    end

  end  

end
