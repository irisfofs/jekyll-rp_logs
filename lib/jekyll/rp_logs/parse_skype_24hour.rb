module Jekyll
  module RpLogs

    class Skype24Parser < RpLogs::Parser #This is for the date format [05.06.15 10:58:47]

      # Add this class to the parsing dictionary
      FORMAT_STR = 'Skype24'
      RpLogGenerator.add self

      # Stuff
      class << self
        NICK = /([\w\-\\\[\]\{\}\^\`\|\s\']+)/
        DATE_REGEXP = /(\[\d\d.\d\d.\d\d\s\d\d\:\d\d\:\d\d\])/ 
        FLAGS = /((?:![A-Z]+ )*)/
        BAD_STUFF = /[^a-zA-Z\-\_]/
        # Crappy but works
        USER_AT_HOST = /\(\w+@[^)]+\)/
        #Not needed?    JUNK = /#{DATE_REGEXP} \* #{MODE}#{NICK} (sets mode:|is now known as|(#{USER_AT_HOST} (has joined|Quit|has left))).*$/
        EMOTE = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s(\3)([^\n]*)$/
        TEXT  = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s([^\n]*)$/

        TIMESTAMP_FORMAT = '[%d.%m.%y %H:%M:%S]'

        def parse_line(line, options = {}) 
          case line
         # when JUNK
           # nil
          when EMOTE
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            contents = $5
            flags = $1
            sendername = $3.tr(' ', '-').gsub(BAD_STUFF, "")
            Parser::LogLine.new(date, options, sender: sendername, contents: contents, \
            flags: flags, type: :rp)
          when TEXT
            date = DateTime.strptime($2, TIMESTAMP_FORMAT)
            contents = $4
            flags = $1
            sendername = $3.tr(' ', '-').gsub(BAD_STUFF, "")
            Parser::LogLine.new(date, options, sender: sendername, contents: contents, \
              flags: flags, type: :ooc)
          else
            # Only put text and emotes in the log
            nil
          end
        end
      end

    end  

  end
end
