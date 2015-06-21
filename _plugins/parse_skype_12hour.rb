require_relative "rp_log_converter"
require_relative "rp_parser"

module RpLogs

  class Skype12Parser < RpLogs::Parser #This is for the date format [6/12/2015 7:01:45 PM]

    # Add this class to the parsing dictionary
    FORMAT_STR = 'Skype12'
    RpLogGenerator.add self

    # Stuff
    class << self
      NICK = /([\w\-\\\[\]\{\}\^\`\|\s\'\)\(]+)/
      DATE_REGEXP = /(\[\d?\d\/\d?\d\/\d\d\d\d\s\d?\d\:\d\d\:\d\d\s(AM|PM)\])/ 
      FLAGS = /((?:![A-Z]+ )*)/
	  BAD_STUFF = /[^a-zA-Z\-\_]/
	  
	 # Crappy but works
	  USER_AT_HOST = /\(\w+@[^)]+\)/
#Not needed?	  JUNK = /#{DATE_REGEXP} \* #{MODE}#{NICK} (sets mode:|is now known as|(#{USER_AT_HOST} (has joined|Quit|has left))).*$/
      EMOTE = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s(\4)([^\n]*)$/
      TEXT  = /^#{FLAGS}#{DATE_REGEXP}\s#{NICK}:\s([^\n]*)$/

      TIMESTAMP_FORMAT = '[%m/%d/%Y %I:%M:%S %p]'

      def parse_line(line, options = {}) 
        case line
        #when JUNK
          #nil
        when EMOTE
		print "1"
          date = DateTime.strptime($2, TIMESTAMP_FORMAT)
          contents = $6
		  flags = $1
		  sendername = $4.tr(' ', '-').gsub(BAD_STUFF, "")
          Parser::LogLine.new(date, options, sender: sendername, contents: contents, \
          flags: flags, type: :rp)
        when TEXT
		print "2"
          date = DateTime.strptime($2, TIMESTAMP_FORMAT)
		  contents = $5
		  flags = $1
		  sendername = $4.tr(' ', '-').gsub(BAD_STUFF, "")
          Parser::LogLine.new(date, options, sender: sendername, contents: contents, \
            flags: flags, type: :ooc)
        else
          print "3"
		  # Only put text and emotes in the log
          nil
        end
      end
    end

  end  

end
