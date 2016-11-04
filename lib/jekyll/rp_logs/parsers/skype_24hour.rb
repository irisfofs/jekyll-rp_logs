module Jekyll
  module RpLogs
    # This is for the date format [05.06.15 10:58:47]
    class Skype24Parser < RpLogs::Parser
      # Add this class to the parsing dictionary
      FORMAT_STR = "Skype24"
      RpLogGenerator.add self

      NICK = /(?<nick>[\w\-\\\[\]\{\}\^\`\|\s\']+)/
      DATE_REGEXP = /(?<timestamp>\[\d\d.\d\d.\d\d\s\d\d\:\d\d\:\d\d\])/
      TIMESTAMP_FORMAT = "[%d.%m.%y %H:%M:%S]"
      MSG = /(?<msg>[^\n]*)/
      BAD_STUFF = /[^a-zA-Z\-\_]/
      SPLITTER = /\n(?=#{FLAGS}#{DATE_REGEXP})/


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
