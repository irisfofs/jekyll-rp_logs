module Jekyll
  module RpLogs

    class QuasselnewParser < RpLogs::Parser

      # Add this class to the parsing dictionary
      FORMAT_STR = 'quassel-new'
      RpLogGenerator.add self

      MODE = /([+%@&~!]?)/
      NICK = /(?<nick>[\w\-\\\[\]\{\}\^\`\|]+)/
      DATE_REGEXP = /(?<timestamp>\[\d\d:\d\d:\d\d\] \[\d\d\.\d\d\.\d\d\])/
      TIMESTAMP_FORMAT = '[%H:%M:%S] [%d.%m.%y]'
      MSG = /(?<msg>[^\x00]*)/
      BAD_STUFF = /[^a-zA-Z\-\_ ]/
      SPLITTER = /\n(?=#{FLAGS}#{DATE_REGEXP})/

      JUNK =  /#{DATE_REGEXP}\t<?-?->?\t.*$/ 
      EMOTE = /^#{FLAGS}#{DATE_REGEXP} -\*- #{NICK}\s*#{MSG}$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP} <#{MODE}#{NICK}[^>]*>\s*#{MSG}$/

      

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