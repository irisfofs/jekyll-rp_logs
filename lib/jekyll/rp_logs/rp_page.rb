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
          @tag_implication_handler = TagImplicationHandler.new(config)
        end
      end

      def initialize(page)
        @page = page

        # If the tags exist, try to convert them to a list of Tag objects
        return unless self[:rp_tags].is_a?(String)
        self[:rp_tags] = Tag[self[:rp_tags].split(",")]
      end

      def stats
        self[:stats].stat
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

      def tags
        self[:rp_tags]
      end

      def tag_strings
        tags.map(&:to_s)
      end

      def tag_set
        if tags.uniq.length == tags.length
          tags.to_set
        else
          tags.group_by{|i|i.to_s}.each_with_object([]){|(_,v),o|
            if v.length == 1
              o << v[0]
            else
              tag = nil
              v.each_with_object{|t|
                if tag
                  tag.update_stats! t.stats
                else
                  tag = t
                end
              }
              o << tag
            end
          }.to_set 
        end
      end

      def arc_description
        self[:arc_description]
      end

      def canon
        self[:canon] ? "canon" : "noncanon"
      end
 
      def description
         self[:description]
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
        self[:rp_tags] = self.class.tag_implication_handler.update_tags(tag_set).to_a
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
        nicks = Hash.new({})
        last_time = 0
        compiled_lines.each do |line|
          if line.output_type == :rp
            sender = "char:#{line.sender}"
            if nicks.has_key? sender
              nicks[sender]["lines"] += 1
              nicks[sender]["wordcount"] += line.contents.split.count
              nicks[sender]["characters"] += line.contents.length
            else
              nicks[sender] = { "lines"=>1, "wordcount"=>line.contents.split.count,
                  "characters"=>line.contents.length, "timelines" =>0, "time"=>0}
            end
            if line.timestamp.to_time.to_i  - last_time <= 30*60
              nicks[sender]["timelines"] += 1
              nicks[sender]["time"] += line.timestamp.to_time.to_i  - last_time
            end
            last_time = line.timestamp.to_time.to_i
          end
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
          nick_tags = stats[:nicks].keys.map! { |n| Tag.new(n) }
          nick_tags.each{|n| n.update_stats! stats[:nicks][n.to_s]}
          self[:rp_tags] = (nick_tags.to_set.merge self[:rp_tags]).to_a.sort
        end
        update_tags

        self[:end_date] = stats[:end_date]
        self[:start_date] ||= stats[:start_date]

        self[:stats] = Tag.new("page_stats")
        self[:rp_tags].each{|tag|
          self[:stats].update_stats! tag.stats if tag.tag_type == "character"
        }
      end
    end
  end
end
