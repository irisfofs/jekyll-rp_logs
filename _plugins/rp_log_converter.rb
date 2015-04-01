module RpLogs

  class RpLogGenerator < Jekyll::Generator
    safe true
    priority :low

    @@parsers = {}

    def RpLogGenerator.add(parser) 
      @@parsers[parser::FORMAT_STR] = parser
    end

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
          # puts page.inspect
          # puts page['tags']
          convertRp page
          key = if page.data['canon'] then 'canon' else 'noncanon' end
          index.data['rps'][key].push page
        }
    end

    def convertRp(page)
      page.content = @@parsers[page.data['format']].compile page.content
    end

  end

  class Parser
    FORMAT_STR = nil

    class LogLine
      MAX_SECONDS_BETWEEN_POSTS = 3
      RP_FLAG = '!RP'
      OOC_FLAG = '!OOC'

      attr :timestamp, :sender, :contents
      attr :flags
      # Some things depend on the original type of the line (nick format)
      attr :base_type
      attr :output_type

      def initialize(timestamp, sender, contents, flags, type) 
        @timestamp = timestamp
        @sender = sender
        @contents = contents
        @flags = flags.split(' ')

        @base_type =  type
        if flags.include? RP_FLAG then
          @output_type = :rp
        elsif flags.include? OOC_FLAG then
          @output_type = :ooc
        else
          @output_type = type
        end
      end

      def output
        anchor = @timestamp.strftime('%Y-%m-%d_%H:%M:%S')
        ts_out = "<a name=\"#{anchor}\" href=\"##{anchor}\">#{@timestamp.strftime('%H:%M')}</a>"

        sender_out = nil
        case @base_type
        when :rp
          sender_out = "  * #{@sender}"
        when :ooc
          sender_out = " <#{@sender}>" 
        else
          # Explode.
          throw "No known type: #{@base_type}"
        end

        tag_open = nil
        tag_close = "</p>"
        case @output_type
        when :rp 
          tag_open = "<p class=\"rp\">"
        when :ooc
          tag_open = "<p class=\"ooc\">"
        else
          # Explode.
          throw "No known type: #{@output_type}"
        end

        return "#{tag_open}#{ts_out}#{sender_out} #{@contents}#{tag_close}"
      end

      def mergeable_with?(next_line)
        return @output_type == :rp && next_line.output_type == :rp && \
          @sender == next_line.sender && next_line.timestamp - @timestamp <= MAX_SECONDS_BETWEEN_POSTS
      end

      def merge!(next_line)
        # How to handle content..
        @contents += ' ' + next_line.contents
      end
    end
  end

end
