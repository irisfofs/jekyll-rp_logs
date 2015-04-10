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

      index.data['rps']['canon'].sort_by! { |p| p.data['start_date'] }.reverse!
      index.data['rps']['noncanon'].sort_by! { |p| p.data['start_date'] }.reverse!
    end

    def convertRp(page)
      options = get_options page
      page.content, stats = @@parsers[page.data['format']].compile(page.content, options)
      # Turn the nicks into characters
      nick_tags = stats[:nicks].map! { |n| Tag.new('char:' + n) }
      page.data['rp_tags'] = (nick_tags.merge page.data['rp_tags']).to_a.sort
    end

    def get_options(page)
      { :strict_ooc => page.data['strict_ooc'] }
    end
  end

end
