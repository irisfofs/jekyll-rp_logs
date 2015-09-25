module Jekyll
  module RpLogs
    class Page
      extend Forwardable

      # Jekyll::Page object
      attr_reader :page

      def_delegators :@page, :content, :content=, :path, :to_liquid

      def initialize(page)
        @page = page
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
    end
  end
end
