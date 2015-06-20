require_relative "rp_tags"

# Again largely inspired by http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/

module RpLogs

  class TagIndex < Jekyll::Page
    def initialize(site, base, dir, tag, pages)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      # Get tag_index filename
      tag_index = (site.config['rp_tag_index_layout'] || 'tag_index') + '.html'
      self.read_yaml(File.join(base, '_layouts'), tag_index)
      self.data['tag'] = tag # Set which tag this index is for
      # Sort tagged RPs by their start date
      self.data['pages'] = pages.sort_by { |p| p.data['start_date'] }
      tag_title_prefix = site.config['rp_tag_title_prefix'] || 'Tag: '
      self.data['title'] = "#{tag_title_prefix}#{tag}"
    end
  end

  class TagIndexGenerator < Jekyll::Generator
    safe true
    priority :low

    def initialize(config) 
      config['rp_tag_index'] ||= true
      config['rp_tag_dir'] ||= '/tags'
    end

    def generate(site)
      return unless site.config['rp_tag_index']
      
      dir = site.config['rp_tag_dir']
      tags = rps_by_tag(site)
      tags.each_pair { |tag, pages| 
        site.pages << TagIndex.new(site, site.source, File.join(dir, tag.dir), tag, pages)
      }
    end

    # Returns a hash of tags => [pages with tag]
    def rps_by_tag(site) 
      tag_ref = Hash.new { |hash, key| hash[key] = Set.new }
      site.collections[RpLogGenerator::RP_KEY].docs.each { |page| 
          page.data['rp_tags'].each { |tag| tag_ref[tag] << page }
        }
      return tag_ref
    end

  end
end