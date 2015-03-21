module RpLogs

  class RpLogGenerator < Jekyll::Generator
    safe true
    priority :low

    def initialize(config)
      config['rp_convert'] ||= true
    end

    def generate(site)
      return unless site.config['rp_convert']
      @site = site

      # Directory of RPs
      index = site.pages.detect { |page| page.data['rp_index'] }
      index.data['rps'] = {'canon' => [], 'noncanon' => []}

      # Convert all of the posts to be pretty
      site.pages.select { |p| p.data['layout'] == 'rp' }
        .each { |page|
          puts page.inspect
          convertRp page
          key = if page.data['canon'] then 'canon' else 'noncanon' end
          index.data['rps'][key].push page
        }
    end

    def convertRp(page)
      page.content = RpLogs.compile(page.content)
    end

  end

  class << self

    MODE = /[+%@&~!]/
    NICK = /([\w\-\\\[\]\{\}\^\`\|]+)/
    DATE_REGEXP = /[\d\-]{10} (\d\d:\d\d):\d\d/

    def compile(logfile)
      # Strip joins, parts, quits, and other meta stuff
      logfile.gsub!(/^#{DATE_REGEXP}\t<?-->?\t.*$\n/, '')

      # Wrap RP in p.rp tags
      logfile.gsub!(/^#{DATE_REGEXP}\t \*\t#{NICK}(\s+[^(][^\n]*)$/, '<p class="rp">\1  * \2\3</p>')

      # Wrap all nicks in <>s, convert to spaces
      logfile.gsub!(/^(!RP )?(#{DATE_REGEXP})\t(#{MODE}?)#{NICK}\t([^\n]*)$/, '\1\2 <\4\5> \6')
      # Add a space to all nicks without modes
      logfile.gsub!(/^(!RP )?(#{DATE_REGEXP} <)#{NICK}(> [^\n]*)$/, '\1\2 \4\5')

      logfile.gsub!(/^(?:!RP )#{DATE_REGEXP}( <.#{NICK}>[^\n]*)$/, '<p class="rp">\1\2</p>')

      # Merge split posts
      loop do
        x = logfile.gsub!(/^(<p class="rp">\d\d:\d\d  \* #{NICK})([^\n]*?)<\/p>\n\1([^\n]*?)$/, '\1\3\4')
        break if x == nil
      end 

      # Remove the non-ooc meta-mark
      logfile.gsub!(/^!OOC /, '')
      # Redo this stuff because it's gross
      logfile.gsub!(/^#{DATE_REGEXP}([^\n]*)$/, '\1\2')

      # Format the rest of the dates for whatever is left so they get caught by the OOC filter
      logfile.gsub!(/^#{DATE_REGEXP}\t([^\n]*)$/, '\1 \2')

      # Wrap OOC in pre.ooc tags
      logfile.gsub!(/^((?:^\d\d:\d\d[^\n]*\n?)+)\n/, "<p class=\"ooc\">\\1</p>\n")
      # puts logfile

      return logfile
    end
  end
end