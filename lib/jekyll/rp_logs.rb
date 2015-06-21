require "jekyll/rp_logs/version"
require 'jekyll'

module Jekyll
  module RpLogs
    # Your code goes here...
  end
end

Gem.find_files("jekyll/rp_logs/*.rb").each { |path| require path }
