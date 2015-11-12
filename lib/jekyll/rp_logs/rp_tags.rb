# Largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module Jekyll
  module RpLogs
    # Holds tag information
    class Tag
      TYPES = [:meta, :character, :general].freeze
      CHAR_FLAG = /^char:(?<char_name>.*)/
      META_TAGS = /(safe|questionable|explicit|canon|noncanon|complete|incomplete)/

      TYPE_CLASSES = {
        character: ["rp-tag-character"],
        meta: ["rp-tag-meta"],
        general: []
      }.freeze

      attr_accessor :dir, :name, :type

      ##
      # Inspired by Hash, convert a list of strings to a list of Tags.
      def self.[](*args)
        args[0].map { |t| Tag.new t }
      end

      def initialize(name)
        # inspect types
        my_name = name.strip
        if CHAR_FLAG =~ my_name
          @name = $LAST_MATCH_INFO[:char_name]
          @type = :character
        else
          @name = my_name.downcase
          @type = @name =~ META_TAGS ? :meta : :general
        end

        @dir = name_to_dir(@name)
      end

      def to_s
        if type == :character
          "char:#{name}"
        else
          name
        end
      end

      def eql?(other)
        self.class.equal?(other.class) && (name == other.name && type == other.type)
      end

      def hash
        name.hash
      end

      def <=>(o)
        if self.class == o.class && type == o.type
          name <=> o.name
        elsif type == :character
          -1
        elsif o.type == :character
          1
        elsif type == :meta
          -1
        elsif o.type == :meta
          1
        else
          nil
        end
      end

      def inspect
        self.class.name + "[" + @name + ", " + @dir + "]"
      end

      def to_liquid
        # Liquid wants a hash, not an object.
        { "name" => @name, "dir" => @dir, "classes" => classes }
      end

      def classes
        TYPE_CLASSES[@type].join " "
      end

      private

      # Map a tag to its directory name. Unsafe characters are replaced with
      # underscores. This restricts the dir name to safe characters in URLs.
      def name_to_dir(name)
        name.gsub(/[^-A-Za-z0-9_|\[\]]/, "_")
      end
    end
  end
end
