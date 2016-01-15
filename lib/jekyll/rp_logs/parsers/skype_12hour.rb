module Jekyll
  module RpLogs
    # This is for the date format [6/12/2015 7:01:45 PM]
    class Skype12Parser < RpLogs::Parser
      # Add this class to the parsing dictionary
      FORMAT_STR = "Skype12"
      RpLogGenerator.add self

      NICK = /(?<nick>[\w\-\\\[\]{}\^`|\s')(]+)/
      DATE_REGEXP = /(?<timestamp>\[\d?\d\/\d?\d\/\d\d\d\d\s\d?\d\:\d\d\:\d\d\s(AM|PM)\])/
      TIMESTAMP_FORMAT = "[%m/%d/%Y %I:%M:%S %p]"
      MSG = /(?<msg>[^\n]*)/
      BAD_STUFF = /[^a-zA-Z\-\_]/

      EMOTE = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s\k<nick>#{MSG}$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s#{MSG}$/

      def self.parse_line(line, options = {})
        case line
        when EMOTE
          type = :rp
        when TEXT
          type = :ooc
        else
          # Only put text and emotes in the log
          return nil
        end
        # Preserve all the matches before the gsub
        date = DateTime.strptime($LAST_MATCH_INFO[:timestamp], TIMESTAMP_FORMAT)
        contents = $LAST_MATCH_INFO[:msg]
        flags = $LAST_MATCH_INFO[:flags]
        sendername = $LAST_MATCH_INFO[:nick].tr(" ", "-").gsub(BAD_STUFF, "")
        LogLine.new(
          date,
          options,
          sender: sendername,
          contents: contents,
          flags: flags,
          type: type
        )
      end
    end
  end
end
