# Again largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

require "yaml"

module Jekyll
  module RpLogs
    class TagIndex < Jekyll::Page
      def initialize(site, base, dir, tag, pages)
        @site = site
        @base = base
        @dir = dir
        @name = "index.html"

        process(@name)
        # Get tag_index filename
        tag_index = (site.config["rp_tag_index_layout"] || "tag_index") + ".html"
        read_yaml(File.join(base, "_layouts"), tag_index)
        data["tag"] = tag # Set which tag this index is for
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
        data["description"] = self.tag_config(site.config)["tag_descriptions"][tag.to_s]

        # Sort tagged RPs by their start date
        data["pages"] = pages.sort_by { |p| p.data["start_date"] }
        tag_title_prefix = site.config["rp_tag_title_prefix"] || "Tag: "
        data["title"] = "#{tag_title_prefix}#{tag.name}"
      end
    end

    class TagIndexGenerator < Jekyll::Generator
      safe true
      # Needs to run after RpLogGenerator
      priority :low

      def initialize(config)
        config["rp_tag_index"] ||= true
        config["rp_tag_dir"] ||= "/tags"
      end

      def generate(site)
        return unless site.config["rp_tag_index"]

        dir = site.config["rp_tag_dir"]
        tags = rps_by_tag(site)
        tags.each_pair do |tag, pages|
          site.pages << TagIndex.new(site, site.source, File.join(dir, tag.dir), tag, pages)
        end
        Jekyll.logger.info "#{tags.size} tag pages generated."
      end

      # Returns a hash of tags => [pages with tag]
      private def rps_by_tag(site)
        tag_ref = Hash.new { |hash, key| hash[key] = Set.new }
        site.collections[RpLogGenerator.rp_key].docs.each do |page|
          page.data["rp_tags"].each { |tag| tag_ref[tag] << page }
        end
        tag_ref
      end
    end
  end
end
