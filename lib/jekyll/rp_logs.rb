require "jekyll/rp_logs/version"
require 'jekyll'

module Jekyll
  module RpLogs

  end
end

# Require the main converter plugin first
require 'jekyll/rp_logs/rp_log_converter'
require 'jekyll/rp_logs/rp_tag_index'

# Now require all of the parsers
Gem.find_files("jekyll/rp_logs/parse*.rb").each { |path| require path }

# Require the rake tasks
require 'jekyll/rp_logs/rp_tasks'
