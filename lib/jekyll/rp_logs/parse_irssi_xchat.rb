module Jekyll
  module RpLogs
    class IrssiXChatParser < RpLogs::Parser
      # Add this class to the parsing dictionary
      FORMAT_STR = "irssi-xchat"
      RpLogGenerator.add self

      DATE_REGEXP = /(?<timestamp>\d\d:\d\d)/
      TIMESTAMP_FORMAT = "%H:%M"

      MSG = /(?<msg>[^\n]*)/

      # TODO: Update to match join/part/quit format
      JUNK =  /#{DATE_REGEXP}\t<?-->?\t.*$/
      EMOTE = /^#{FLAGS}#{DATE_REGEXP} {16}\* \| #{NICK}\s+#{MSG}$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP} <#{MODE}? *#{NICK}> \| #{MSG}$/

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
        date = DateTime.strptime($LAST_MATCH_INFO[:timestamp], TIMESTAMP_FORMAT)
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
