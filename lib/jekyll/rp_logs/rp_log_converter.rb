require_relative "rp_parser"
require_relative "rp_logline"
require_relative "rp_page"
require_relative "rp_arcs"
require_relative "rp_tags"

module Jekyll
  module RpLogs
    # Consider renaming since it is more of a converter in practice
    # It can't actually be a subclass of Jekyll::Converter because those work
    # very differently. Converters convert single files, while a generator can
    # work with the entire site.
    class RpLogGenerator < Jekyll::Generator
      safe true
      priority :normal

      @parsers = {}

      class << self
        attr_reader :parsers, :rp_key

        def add(parser)
          @parsers[parser::FORMAT_STR] = parser
        end

        ##
        # Extract global settings from the config file.
        # The rp directory and collection name is pulled out; it must be the
        # first collection defined.
        def extract_settings(config)
          @rp_key = config["collections"].keys[0].freeze
        end
      end

      def initialize(config)
        # Should actually probably complain if things are undefined or missing
        config["rp_convert"] = true unless config.key? "rp_convert"

        RpLogGenerator.extract_settings(config)
        LogLine.extract_settings(config)
        Page.extract_settings(config)

        Jekyll.logger.info "Loaded jekyll-rp_logs #{RpLogs::VERSION}"
      end

      def generate(site)
        return unless site.config["rp_convert"]

        # There doesn't seem to be a better way to add this to all pages than
        # by modifying the configuration file, which is added onto the `site`
        # liquid variable.
        site.config["rp_logs_version"] = RpLogs::VERSION

        Jekyll.logger.info("RpLogGenerator#generate called")

        main_index, arc_index = extract_indexes(site)

        disable_liquid_rendering(site)
        # Pull out all the pages that are error-free
        rp_pages = extract_valid_rps(site)

        convert_all_pages(site, main_index, arc_index, rp_pages)
      end

      private

      ##
      # Convenience method for accessing the collection key name
      def rp_key
        self.class.rp_key
      end

      ##
      #
      def extract_indexes(site)
        # Directory of RPs
        main_index = site.pages.find { |page| page.data["rp_index"] }
        Jekyll.logger.abort_with "Main index page missing" if main_index.nil?
        main_index.data["rps"] = { "canon" => [], "noncanon" => [] }

        # Arc-style directory
        arc_index = site.pages.find { |page| page.data["rp_arcs"] }
        Jekyll.logger.abort_with "Arc index page missing" if arc_index.nil?

        site.data["menu_pages"] = [main_index, arc_index]
      end

      ##
      # Redefine the #render_with_liquid? method for every RP Document. This
      # speeds up the rendering process a little, and also avoids Liquid
      # throwing a fit if someone typed {{ in the log.
      def disable_liquid_rendering(site)
        site.collections[rp_key].docs.each do |doc|
          # https://github.com/jekyll/jekyll/blob/6e8fd8cb50eab4dab527eaaa0b23d08593b9972b/lib/jekyll/document.rb#L150
          def doc.render_with_liquid?
            false
          end
        end
      end

      ##
      # Returns a list of RpLogs::Page objects that are error-free.
      def extract_valid_rps(site)
        site.collections[rp_key].docs.map { |p| RpLogs::Page.new(p) }
          .reject do |p|
            message = p.errors?(self.class.parsers)
            skip_page(site, p, message) if message
            message
          end
      end

      def convert_all_pages(site, main_index, arc_index, rp_pages)
        arcs = Hash.new { |hash, key| hash[key] = Arc.new(key) }
        no_arc_rps = []

        # Convert all of the posts to be pretty
        # Also build up our hash of tags
        rp_pages.each do |page|
          convert_page(page, site, main_index, arcs, no_arc_rps)
        end

        Jekyll.logger.info(
          "#{site.collections[rp_key].docs.size} RPs converted.")

        sort_arcs(arcs, no_arc_rps, arc_index)
        sort_chronologically! main_index.data["rps"]["canon"]
        sort_chronologically! main_index.data["rps"]["noncanon"]
      end

      def convert_page(page, site, main_index, arcs, no_arc_rps)
        # Skip if something goes wrong
        return unless convert_rp(site, page)

        key = page.canon
        # Add key for canon/noncanon
        main_index.data["rps"][key] << page
        # Add tag for canon/noncanon
        page[:rp_tags] << (Tag.new key)
        page[:rp_tags].sort!

        arc_name = page[:arc_name]
        if arc_name && !arc_name.empty?
          arc_name.each { |n| arcs[n] << page }
        else
          no_arc_rps << page
        end

        Jekyll.logger.debug "Converted #{page.basename}"
      rescue
        # Catch all for any other exception encountered when parsing a page
        skip_page(site, page,
                  "Error parsing #{page.basename}: #{$ERROR_INFO.inspect}")
        # Raise exception, so Jekyll prints backtrace if run with --trace
        raise $ERROR_INFO
      end

      def sort_arcs(arcs, no_arc_rps, arc_index)
        arcs.each_key { |key| sort_chronologically! arcs[key].rps }
        arc_index.data["rps"] = sort_arcs_and_pages(arcs, no_arc_rps)
      end

      def sort_arcs_and_pages(arcs, no_arc_rps)
        combined_rps = no_arc_rps.map { |x| ["rp", x] } +
                       arcs.values.map { |x| ["arc", x] }
        combined_rps.sort_by! do |type, x|
          case type
          when "rp"
            x[:time_line] || x[:start_date]
          when "arc"
            x.start_date
          end
        end.reverse!
      end

      def sort_chronologically!(pages)
        # Check pages for invalid time_line value
        pages.each do |p|
          if p[:time_line] && !p[:time_line].is_a?(Date)
            Jekyll.logger.error "Malformed time_line #{p[:time_line]} in file #{p.path}"
            fail "Malformed time_line date, must be in the format YYYY-MM-DD"
          end
        end
        # Sort pages by time_line if present or start_date otherwise
        pages.sort_by! { |p| p[:time_line] || p[:start_date] }.reverse!
      end

      def convert_rp(site, page)
        msg = catch :skip_page do
          page.convert_rp(self.class.parsers)
          return true
        end
        skip_page(site, page, msg)
        false
      end

      ##
      # Skip the page. Removes it from the site collection, and outputs a
      # warning message saying it was skipped with the given reason.
      def skip_page(site, page, message)
        site.collections[rp_key].docs.delete page.page
        Jekyll.logger.warn "Skipping #{page.basename}: #{message}"
      end
    end
  end
end
