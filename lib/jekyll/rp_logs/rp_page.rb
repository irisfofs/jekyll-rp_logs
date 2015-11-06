require "forwardable"
require_relative "rp_tags"
require_relative "rp_tag_implication_handler"

module Jekyll
  module RpLogs
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
        self[:rp_tags] = Tag[self[:rp_tags].split(",")] if self[:rp_tags].is_a?(String)
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

      ##
      # Check this page for errors, using the provided list of supported parse
      # formats
      #
      # Returns false if there is no error
      # Returns error_message if there is an error
      def errors?(supported_formats)
        # Verify that formats are specified
        if self[:format].nil? || self[:format].empty?
          return "No formats specified"
        end

        # Verify that the parser for each format exists
        self[:format].each do |format|
          return "Format #{format} does not exist." unless supported_formats[format]
        end

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
    end
  end
end
