require "yaml"
require "forwardable"
require_relative "rp_tags"
require_relative "rp_tag_implication_handler"

module Jekyll
  module RpLogs
    ##
    # A wrapper for Jekyll::Page that provides RpLogs related functionality.
    #
    # Handles checking for errors, merging lines, and collecting statistics.
    class Page
      extend Forwardable
      def_delegators :@page, :basename, :content, :content=, :path, :to_liquid

      # Jekyll::Page object
      attr_reader :page

      class << self
        attr_reader :tag_implication_handler

        def extract_settings(config)
          @tag_implication_handler = TagImplicationHandler.new(self.tag_config(config))
        end
      end

      def initialize(page)
        @page = page

        # If the tags exist, try to convert them to a list of Tag objects
        return unless self[:rp_tags].is_a?(String)
        self[:rp_tags] = Tag[self[:rp_tags].split(",")]
      end

      ##
      # Pass the request along to the page's data hash, and allow symbols to be
      # used by converting them to strings first.
      def [](key)
        @page.data[key.to_s]
      end

      def []=(key, value)
        @page.data[key.to_s] = value
      end

      def self.tag_config(config)
        if config['source'] && config["tag_file"]
           if File.exists?(File.join(config['source'],config["tag_file"]))
              @tag_config = YAML.load_file(File.join(config['source'],config["tag_file"]))
           else
              @tag_config = config
           end
        else
           @tag_config = config
        end
      end

      def tags
        self[:rp_tags]
      end

      def tag_strings
        tags.map(&:to_s)
      end

      def arc_description
        self[:arc_description]
      end

      def canon
        self[:canon] ? "canon" : "noncanon"
      end

      def convert_rp(parsers)
        compiled_lines = convert_all_lines(parsers)

        merge_lines! compiled_lines
        stats = extract_stats compiled_lines

        # A decent amount of this could be moved into Page
        split_output = compiled_lines.map(&:output)
        page.content = split_output.join("\n")

        update_page_properties(stats)

        true
      end

      ##
      # Check this page for errors, using the provided list of supported parse
      # formats
      #
      # Returns false if there is no error
      # Returns error_message if there is an error
      def errors?(supported_formats)
        # Check formatting errors
        format_error = format_errors?(supported_formats)
        return format_error if format_error

        # Verify that tags exist
        return "No tags specified" if self[:rp_tags].nil?

        # Verify that arc names are in the proper format
        if self[:arc_name] && !self[:arc_name].respond_to?("each")
          return "arc_name must be blank or a YAML list"
        end

        false
      end

      def options
        { strict_ooc: self[:strict_ooc],
          merge_text_into_rp: self[:merge_text_into_rp],
          splits_by_character: self[:splits_by_character] }
      end

      ##
      # Updates tags with implications and aliases.
      def update_tags
        self[:rp_tags] = Tag[self.class.tag_implication_handler.update_tags(tag_strings.to_set)]
        self
      end

      private

      def format_errors?(supported_formats)
        # Verify that formats are specified
        if self[:format].nil? || self[:format].empty?
          return "No formats specified"
        end

        # Verify that the parser for each format exists
        self[:format].each do |format|
          return "Format #{format} does not exist." unless supported_formats[format]
        end

        false
      end

      def convert_all_lines(parsers)
        compiled_lines = []
        parse_split = parse_get_split(parsers)
        content.split(parse_split).each  { |raw_line|
          log_line = parse_line(parsers, raw_line)
          compiled_lines << log_line if log_line
        }

        if compiled_lines.length == 0
          throw :skip_page, "No lines were matched by any format."
        end

        compiled_lines
      end
     
      ##
      # Return the split regex compiled from all parsers 
      #
      def parse_get_split(parsers)
        parse_split = ""
        self[:format].each do |format|
            if parse_split != ""  # && defined?(parsers[format]::SPLITTER)
                parse_split = /#{parse_split}|#{parsers[format]::SPLITTER}/
            else 
                parse_split = parsers[format]::SPLITTER
            end
        #print(count ++)
        end
        return parse_split if defined?(parse_split)
        #/\n/
      end

      ##
      # Return the line parsed by the first matching parser, or nil if
      # there are no matches.
      def parse_line(parsers, raw_line)
        self[:format].each do |format|
          log_line = parsers[format].parse_line(raw_line, options)
          return log_line if log_line
        end
        nil
      end

      ##
      # Merge all lines that can be merged. Modifies the list of lines.
      def merge_lines!(compiled_lines)
        last_line = nil
        compiled_lines.reject! do |line|
          if last_line.nil? || !(last_line.mergeable_with? line)
            last_line = line
            false
          else
            last_line.merge! line
            # Delete the current line from output and maintain last_line
            # in case we need to merge multiple times.
            true
          end
        end
      end

      ##
      # Returns various stats about the line content:
      # - nicks: The nicks involved
      # - end_date: The timestamp of the last post
      # - start_date: The timestamp of the first post
      def extract_stats(compiled_lines)
        nicks = Set.new
        compiled_lines.each do |line|
          nicks << line.sender if line.output_type == :rp
        end

        { nicks: nicks,
          end_date: compiled_lines[-1].timestamp,
          start_date: compiled_lines[0].timestamp }
      end

      ##
      # Update properties of the page based on statistics.
      # - Adds tags based on nicks involved, if the infer_char_tags option is
      #   set to true.
      # - Updated end and start date.
      def update_page_properties(stats)
        if self[:infer_char_tags]
          # Turn the nicks into characters
          nick_tags = stats[:nicks].map! { |n| Tag.new("char:#{n}") }
          self[:rp_tags] = (nick_tags.merge self[:rp_tags]).to_a.sort
        end
        update_tags

        self[:end_date] = stats[:end_date]
        self[:start_date] ||= stats[:start_date]
      end
    end
  end
end
