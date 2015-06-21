# Largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module Jekyll
  module RpLogs

    TAG_NAME_MAP = {
      "#"  => "sharp",
      "/"  => "slash",
      "\\" => "backslash",
      " "  => "_"
    }

    # Holds tag information
    class Tag

      attr_accessor :dir, :name, :type

      TYPES = [:meta, :character, :general]
      CHAR_FLAG = /char:(.*)/
      META_TAGS = /(safe|questionable|explicit|canon|noncanon|complete|incomplete)/

      TYPE_CLASSES = {
        :character => ['rp-tag-character'],
        :meta => ['rp-tag-meta'],
        :general => []
      }

      def initialize(name)
        # inspect types
        name.strip!
        if (name =~ CHAR_FLAG) == 0 then
          @name = $1
          @type = :character
        else
          @name = name.downcase
          @type = @name =~ META_TAGS ? :meta : :general
        end

        @dir = name_to_dir(@name)
      end

      def to_s
        self.name
      end

      def eql?(tag)
        self.class.equal?(tag.class) && (self.name == tag.name && self.type == tag.type)
      end

      def hash
        self.name.hash
      end

      def <=>(o)
        if self.class == o.class && self.type == o.type
          self.name <=> o.name 
        elsif self.type == :character
          -1
        elsif o.type == :character
          1 
        elsif self.type == :meta
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

        { "name" => @name, "dir" => @dir, "classes" => self.classes }
      end

      def classes      
        TYPE_CLASSES[@type].join ' '
      end

      private

      # Map a tag to its directory name. Certain characters are escaped,
      # using the TAG_NAME_MAP constant, above.
      def name_to_dir(name)
        s = ""
        name.each_char do |c|
          if (c =~ /[-A-Za-z0-9_|\[\]]/) != nil
            s += c
          else
            c2 = TAG_NAME_MAP[c]
            if not c2
              msg = "Bad character '#{c}' in tag '#{name}'"
              puts("*** #{msg}")
              raise Exception.new(msg)
            end
            s += "#{c2}"
          end
        end
        s
      end
    end
  end
end
