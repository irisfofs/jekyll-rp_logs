# Largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module Jekyll
  module RpLogs

    # Holds arc information
    class Arc

      attr_accessor :name, :rps

      def initialize(name)
        # inspect types
        name.strip!
        @name = name

        @rps = []
        # potential future idea: directories for each arc
      end

      def <<(rp_page) 
        @rps << rp_page
      end

      def start_date
        @rps.map { |rp_page| rp_page.data['start_date'] }.min
      end

      def end_date
        @rps.map { |rp_page| rp_page.data['last_post_time'] }.max
      end

      def is_arc?
        true
      end

      def to_s
        self.name
      end

      def eql?(arc)
        self.class.equal?(arc.class) && (self.name == arc.name) && (self.rps.equal?(arc.rps))
      end

      def hash
        self.name.hash
      end

      # actually by... start.. date?
      def <=>(o)
        if self.class == o.class 
          self.name <=> o.name 
        else
          nil
        end
      end

      def inspect
        self.class.name + "[" + @name + "]"
      end

      def to_liquid
        # Liquid wants a hash, not an object.

        { "name" => @name, "rps" => @rps }
      end

    end
  end
end
