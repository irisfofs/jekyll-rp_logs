require_relative "rp_parser"
require_relative "rp_page"
require_relative "rp_arcs"
require_relative "rp_tags"

module Jekyll
  module RpLogs
    # Consider renaming since it is more of a converter in practice
    class RpLogGenerator < Jekyll::Generator
      safe true
      priority :normal

      RP_KEY = "rps"

      @parsers = {}

      class << self
        attr_reader :parsers

        def add(parser)
          @parsers[parser::FORMAT_STR] = parser
        end
      end

      def initialize(config)
        # Should actually probably complain if things are undefined or missing
        config["rp_convert"] ||= true
      end

      def skip_page(page, message)
        # TODO: prettify
        @site.collections[RP_KEY].docs.delete page.page
        print "\nSkipping #{page.path}: #{message}"
      end

      def has_errors?(page)
        # Verify that formats are specified
        if page[:format].nil? || page[:format].length == 0
          skip_page(page, "No formats specified")
          return true
        else
          # Verify that the parser for each format exists
          page[:format].each { |format|
            if self.class.parsers[format].nil?
              skip_page(page, "Format #{format} does not exist.")
              return true
            end
          }
        end

        # Verify that tags exist
        if page[:rp_tags].nil?
          skip_page(page, "No tags specified")
          return true
        # Verify that arc names are in the proper format
        elsif page[:arc_name] && !page[:arc_name].respond_to?("each")
          skip_page(page, "arc_name must be blank or a YAML list")
          return true
        end

        false
      end

      def generate(site)
        return unless site.config["rp_convert"]
        @site = site

        # Directory of RPs
        index = site.pages.detect { |page| page.data["rp_index"] }
        index.data["rps"] = { "canon" => [], "noncanon" => [] }

        # Arc-style directory
        arc_page = site.pages.detect { |page| page.data["rp_arcs"] }

        site.data["menu_pages"] = [index, arc_page]

        arcs = Hash.new { |hash, key| hash[key] = Arc.new(key) }
        no_arc_rps = []

        # Convert all of the posts to be pretty
        # Also build up our hash of tags
        site.collections[RP_KEY].docs.map { |p| RpLogs::Page.new(p) }
          .each { |page|
            # because we're iterating over a selected array, we can delete from the original
            begin
              next if has_errors? page

              page[:rp_tags] = page[:rp_tags].split(",").map { |t| Tag.new t }

              # Skip if something goes wrong
              next unless convert_rp page

              key = page[:canon] ? "canon" : "noncanon"
              # Add key for canon/noncanon
              index.data["rps"][key] << page
              # Add tag for canon/noncanon
              page[:rp_tags] << (Tag.new key)
              page[:rp_tags].sort!

              arc_name = page[:arc_name]
              if arc_name
                arc_name.each { |n| arcs[n] << page }
              else
                no_arc_rps << page
              end
            rescue
              # Catch all for any other exception encountered when parsing a page
              skip_page(page, "Error parsing #{page.path}: #{$ERROR_INFO.inspect}\n")
              # Raise exception, so Jekyll prints backtrace if run with --trace
              raise $ERROR_INFO
            end
          }

        arcs.each_key { |key| sort_chronologically! arcs[key].rps }
        combined_rps = no_arc_rps.map { |x| ["rp", x] } + arcs.values.map { |x| ["arc", x] }
        combined_rps.sort_by! { |type, x|
          case type
          when "rp"
            x[:time_line] || x[:start_date]
          when "arc"
            x.start_date
          end
        }.reverse!
        arc_page.data["rps"] = combined_rps

        sort_chronologically! index.data["rps"]["canon"]
        sort_chronologically! index.data["rps"]["noncanon"]
      end

      def sort_chronologically!(pages)
        # Check pages for invalid time_line value
        pages.each do |p|
          if p[:time_line] && !p[:time_line].is_a?(Date)
            puts "Malformed time_line #{p[:time_line]} in file #{p.path}"
            fail "Malformed time_line date"
          end
        end
        # Sort pages by time_line if present or start_date otherwise
        pages.sort_by! { |p| p[:time_line] || p[:start_date] }.reverse!
      end

      def convert_rp(page)
        options = get_options page

        compiled_lines = []
        page.content.each_line { |raw_line|
          page[:format].each { |format|
            log_line = self.class.parsers[format].parse_line(raw_line, options)
            if log_line
              compiled_lines << log_line
              break
            end
          }
        }

        if compiled_lines.length == 0
          skip_page(page, "No lines were matched by any format.")
          return false
        end

        merge_lines! compiled_lines
        stats = extract_stats compiled_lines

        split_output = compiled_lines.map(&:output)
        page.content = split_output.join("\n")

        if page[:infer_char_tags]
          # Turn the nicks into characters
          nick_tags = stats[:nicks].map! { |n| Tag.new("char:" + n) }
          page[:rp_tags] = (nick_tags.merge page[:rp_tags]).to_a.sort
        end

        page[:end_date] = stats[:end_date]
        page[:start_date] ||= stats[:start_date]

        true
      end

      def get_options(page)
        { strict_ooc: page[:strict_ooc],
          merge_text_into_rp: page[:merge_text_into_rp] }
      end

      def merge_lines!(compiled_lines)
        last_line = nil
        compiled_lines.reject! { |line|
          if last_line.nil?
            last_line = line
            false
          elsif last_line.mergeable_with? line
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

        { nicks: nicks,
          end_date: compiled_lines[-1].timestamp,
          start_date: compiled_lines[0].timestamp }
      end
    end
  end
end
