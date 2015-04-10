require_relative "rp_tags"
require_relative "rp_parser"

module RpLogs

  class RpLogGenerator < Jekyll::Generator
    safe true
    priority :normal

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
      # Also build up our hash of tags
      site.pages.select { |p| p.data['layout'] == 'rp' }
        .each { |page|
          # puts page.inspect
          page.data['rp_tags'] = page.data['rp_tags'].split(',').map { |t| Tag.new t }.sort
          
          convertRp page

          key = if page.data['canon'] then 'canon' else 'noncanon' end
          index.data['rps'][key].push page
        }

      start_time_compare = lambda { |a, b| 
        a_date = a.data['start_date']
        b_date = b.data['start_date']
        # puts "#{a_date.class}: #{a_date} <=> #{b_date.class}: #{b_date}"
        if a_date.is_a?(Date) && b_date.is_a?(Date) then 
          a_date <=> b_date 
        # Sort dated RPs before undated ones
        elsif a_date.is_a?(Date) then
          1
        elsif b_date.is_a?(Date) then
          -1
        else
          0
        end
      }
      index.data['rps']['canon'].sort! { |a, b| start_time_compare.call(a, b) }.reverse!
      index.data['rps']['noncanon'].sort! { |a, b| start_time_compare.call(a, b) }.reverse!
    end

    def convertRp(page)
      page.content = @@parsers[page.data['format']].compile page.content
    end
  end

end
