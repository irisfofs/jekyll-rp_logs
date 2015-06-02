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

      # Arc-style directory
      arc_page = site.pages.detect { |page| page.data['rp_arcs'] }

      arcs = Hash.new { |hash, key| hash[key] = Arc.new(key) }
      no_arc_rps = []

      # Convert all of the posts to be pretty
      # Also build up our hash of tags
      site.pages.select { |p| p.data['layout'] == 'rp' }
        .each { |page|
          # puts page.inspect
          page.data['rp_tags'] = page.data['rp_tags'].split(',').map { |t| Tag.new t }

          convertRp page

          key = if page.data['canon'] then 'canon' else 'noncanon' end
          # Add key for canon/noncanon
          index.data['rps'][key] << page
          # Add tag for canon/noncanon
          page.data['rp_tags'] << (Tag.new key)
          page.data['rp_tags'].sort!

          arc_name = page.data['arc_name']
          if arc_name then
            arc_name.each { |n| arcs[n] << page }
          else
            no_arc_rps << page
          end
        }

      arcs.each_key { |key| sort_chronologically! arcs[key].rps } 
      combined_rps = no_arc_rps.map { |x| ['rp', x] } + arcs.values.map { |x| ['arc', x] }
      combined_rps.sort_by! { |type,x|
        case type
        when 'rp'
          x.data['start_date']
        when 'arc'
          x.start_date 
        end
      }.reverse!
      arc_page.data['rps'] = combined_rps 

      sort_chronologically! index.data['rps']['canon']
      sort_chronologically! index.data['rps']['noncanon']
    end

    def sort_chronologically!(pages) 
      pages.sort_by! { |p| p.data['start_date'] }.reverse!
    end

    def convertRp(page)
      options = get_options page

      compiled_lines = []
      page.content.each_line { |raw_line| 
        page.data['format'].each { |format| 
          log_line = @@parsers[format].parse_line(raw_line, options)
          if log_line then
            compiled_lines << log_line 
            break
          end
        }
      }

      merge_lines! compiled_lines
      stats = extract_stats compiled_lines

      split_output = compiled_lines.map { |line| line.output }

      page.content = split_output.join("\n")

      # Turn the nicks into characters
      nick_tags = stats[:nicks].map! { |n| Tag.new('char:' + n) }

      page.data['rp_tags'] = (nick_tags.merge page.data['rp_tags']).to_a.sort
      page.data['end_date'] = stats[:end_date].strftime("%Y-%m-%d")
      page.data['start_date'] ||= stats[:start_date]
    end

    def get_options(page)
      { :strict_ooc => page.data['strict_ooc'],
        :merge_text_into_rp => page.data['merge_text_into_rp'] }
    end

    def merge_lines!(compiled_lines)
      last_line = nil
      compiled_lines.reject! { |line| 
        if last_line == nil then
          last_line = line
          false
        elsif last_line.mergeable_with? line then
          last_line.merge! line
          # Delete the current line from output and maintain last_line 
          # in case we need to merge multiple times.
          true 
        else
          last_line = line
          false
        end
      }
    end

    def extract_stats(compiled_lines) 
      nicks = Set.new
      compiled_lines.each { |line| 
        nicks << line.sender if line.output_type == :rp
      }

      { :nicks => nicks,
        :end_date => compiled_lines[-1].timestamp,
        :start_date => compiled_lines[0].timestamp }
    end
  end

end
