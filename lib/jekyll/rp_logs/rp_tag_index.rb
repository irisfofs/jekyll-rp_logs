# Again largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module Jekyll
  module RpLogs
    class TagIndex < Jekyll::Page
      def initialize(site, base, dir, tag, pages, tags)
        @site = site
        @base = base
        @dir = dir
        @name = "index.html"

        process(@name)
        # Get tag_index filename
        tag_index = (site.config["rp_tag_index_layout"] || "tag_index") + ".html"
        read_yaml(File.join(base, "_layouts"), tag_index)
        data["tag"] = tag # Set which tag this index is for
        data["description"] = site.config["tag_descriptions"][tag.to_s]

        # Sort tagged RPs by their start date
        data["pages"] = pages.sort_by { |p| p.data["start_date"] }
        data["count"] = data["pages"].length

        data["implies"] = site.config["tag_implications"][tag.to_s]
        if data["implies"]; then data["implies"].map! {|t| tags.keys.find{|k| k.to_s == t} || t} end
        data["implied_by"] = site.config["tag_implied_by"][tag.to_s]
        if data["implied_by"]; then data["implied_by"].map! {|t| tags.keys.find{|k| k.to_s == t} || t} end
        data["aliased_by"] = site.config["tag_aliased_by"][tag.to_s]
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
        tag_list = Hash.new
        tag_list.merge! (tags)
        
        tags.each_pair do |tag, pages|
          site.pages << TagIndex.new(site, site.source, File.join(dir, tag.dir), tag, pages,tag_list)
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
