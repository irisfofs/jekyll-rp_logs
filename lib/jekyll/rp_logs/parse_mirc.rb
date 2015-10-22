module Jekyll
  module RpLogs
    class MIRCParser < RpLogs::Parser
      # Add this class to the parsing dictionary
      FORMAT_STR = "MIRC"
      RpLogGenerator.add self

      # Remember to change this for your date format
      # For example, this regex is for, mm dd yy[HH:nn] or 06 14 15[18:48]
      # The default mirc date format is HH:nn
      DATE_REGEXP = /(\d\d \d\d \d\d\[\d\d:\d\d\])/
      # Also make sure to change this - http://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
      # If you are using the default mirc format, this should be "[%H:%M]"
      TIMESTAMP_FORMAT = "%m %d %y[%H:%M]"

      # Crappy but works
      USER_AT_HOST = /\(\w+@[^)]+\)/
      MSG = /(?<msg>[^\n]*)/
      # The ()?((?=\d{4})(\d\d))? bit of code is to remove the  and two random numbers in front of lines.
      # This assumes that you have a two digit date code stating your time stamp.
      JUNK = /()?((?=\d{4})(\d\d))?#{DATE_REGEXP} \* #{MODE}#{NICK} (sets mode:|is now known as|(#{USER_AT_HOST} (has joined|Quit|has left))).*$/
      EMOTE = /^#{FLAGS}()?((?=\d{4})(\d\d))?#{DATE_REGEXP}\s\*\s#{MODE}#{NICK}\s+#{MSG}$/
      TEXT  = /^#{FLAGS}()?((?=\d{4})(\d\d))?#{DATE_REGEXP}\s<#{MODE}#{NICK}>\s#{MSG}$/

      def self.parse_line(line, options = {})
        case line
        when JUNK
          return nil
        when EMOTE
          type = :rp
        when TEXT
          type = :ooc
          mode = $LAST_MATCH_INFO[:mode]
          mode = " " if mode == ""
        else
          # Only put text and emotes in the log
          return nil
        end
        date = DateTime.parse($LAST_MATCH_INFO[:timestamp], TIMESTAMP_FORMAT)
        LogLine.new(
          date,
          options,
          sender: $LAST_MATCH_INFO[:nick],
          contents: $LAST_MATCH_INFO[:msg],
          flags: $LAST_MATCH_INFO[:flags],
          type: type,
          mode: mode
        )
      end
    end
  end
end
