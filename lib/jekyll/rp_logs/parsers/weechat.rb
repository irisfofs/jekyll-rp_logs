module Jekyll
  module RpLogs
    ##
    # Parses logs in the default format of [Weechat](https://weechat.org/)
    class WeechatParser < RpLogs::Parser
      # Add this class to the parsing dictionary
      FORMAT_STR = "weechat"
      RpLogGenerator.add self

      # Date is repeated in each type of message
      DATE_REGEXP = /(?<timestamp>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)/
      TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"
      SPLITTER = /\n(?=#{FLAGS}#{DATE_REGEXP})/


      # Regular expressions for matching each type of line
      JUNK =  /#{DATE_REGEXP}\t<?-->?\t.*$/
      EMOTE = /^#{FLAGS}#{DATE_REGEXP}\t \*\t#{NICK}\s+(?<msg>[^\n]*)$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP}\t#{MODE}#{NICK}\t(?<msg>[^\n]*)$/

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
