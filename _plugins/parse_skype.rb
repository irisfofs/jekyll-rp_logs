require_relative "rp_log_converter"
require_relative "rp_parser"

module RpLogs

  class SkypeParser < RpLogs::Parser #This has been tested on Skype 6.2

    # Add this class to the parsing dictionary
    FORMAT_STR = 'Skype'
    RpLogGenerator.add self

    # Stuff
    class << self
      NICK = /([\w\-\\\[\]\{\}\^\`\|\s\']+)/
      DATE_REGEXP = /(\[\d\d.\d\d.\d\d\s\d\d\:\d\d\:\d\d\])/ 
      FLAGS = /((?:![A-Z]+ )*)/
	  
	 # Crappy but works
	  USER_AT_HOST = /\(\w+@[^)]+\)/
#Not needed?	  JUNK = /#{DATE_REGEXP} \* #{MODE}#{NICK} (sets mode:|is now known as|(#{USER_AT_HOST} (has joined|Quit|has left))).*$/
      EMOTE = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s(\3)([^\n]*)$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s([^\n]*)$/

      TIMESTAMP_FORMAT = '[%d.%m.%y %H:%M:%S]'

      def parse_line(line, options = {}) 
        case line
       # when JUNK
         # nil
        when EMOTE
		
          date = DateTime.strptime($2, TIMESTAMP_FORMAT)
		  sendername = $3.tr(' ', '-').tr("'", "")
          Parser::LogLine.new(date, options, sender: sendername, contents: $5, \
            flags: $1, type: :rp)
        when TEXT
          date = DateTime.strptime($2, TIMESTAMP_FORMAT)
		  sendername = $3.tr(' ', '-').tr("'", "")
          Parser::LogLine.new(date, options, sender: sendername, contents: $4, \
            flags: $1, type: :ooc)
        else
          # Only put text and emotes in the log
          nil
        end
      end
    end

  end  

end
