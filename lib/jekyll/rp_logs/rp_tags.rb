# Largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module Jekyll
  module RpLogs
    ##
    # A tag for RPs. Represents a property of the RP; for instance, a character
    # involved in it, or whether the RP is complete or not, or a rating of the
    # content.
    #
    # Character tags are special in that they are prefixed with `char:`, though
    # this prefix isn't part of the tag name. So the tags `char:Alice` and
    # `Alice` can coexist. It'll just be confusing.
    #
    # Tags are also mapped to directories; this directory hosts an index of all
    # RPs with that tag.
    class Tag
      include Comparable

      TYPES = [:meta, :character, :general].freeze
      CHAR_FLAG = /^char:(?<char_name>.*)/
      META_TAGS = /(safe|questionable|explicit|canon|noncanon|complete|incomplete)/

      # CSS classes to apply to this tag, when displayed
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

      def tag_type
        @type.to_s
      end

      def to_s
        if type == :character
          "char:#{name}"
        else
          name
        end
      end

      def eql?(other)
        self.class.equal?(other.class) &&
          name == other.name &&
          type == other.type
      end

      def hash
        # Can't be name.hash because then `char:alice` and `alice` collide
        to_s.hash
      end

      ##
      # Compares two tags. Character tags are less than meta tags, and meta
      # tags are less than general tags. Two tags of the same type are compared
      # by their names.
      def <=>(other)
        # Assign 'points' to each type of tag. More 'important' tags have
        # higher point values.
        type_points = {
          general: 0,
          meta: 2,
          character: 4
        }
        # The different in point value between the tag types represents the
        # difference in sorting order.
        # - If this tag's type is more important, type_diff <= -2
        # - If the other's type is more important, type_diff  >= 2
        # - If the types are the same, the points cancel out: type_diff == 0
        type_diff = type_points[other.type] -
                    type_points[type]

        # If the types are different, type_diff will overshadow the name
        # comparison (which is -1, 0, or 1).
        comparison = (name <=> other.name) + type_diff
        # Clamp the result to -1, 0, 1
        comparison <=> 0
      end

      def inspect
        "#{self.class.name}[#{@name}, #{@dir}]"
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
