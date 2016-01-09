# spec/integration_spec.rb
require "jekyll"
# This will require all the parsers for us
require "jekyll/rp_logs"
require "jekyll/rp_logs/rp_log_converter"

require "rake"
require "yaml"

# Pull in some gross setup stuff for rakefiles
require_relative "util"

module Jekyll
  module RpLogs
    DEFAULT_CONFIGURATION = Util.gross_setup_stuff

    RSpec.describe RpLogGenerator do
      before(:all) do
        Dir.chdir("dev_site") do
          site = Jekyll::Site.new(DEFAULT_CONFIGURATION)
          capture_stderr { capture_stdout { site.process } }
        end
      end

      describe "on the rendered site" do
        describe "the index page html" do
          subject { File.read(File.join("dev_site", "_site", "index.html")) }

          # Each one should be linked in the file somewhere
          dirs = Util::VALID_TEST_NAMES.map { |n| "<a href=\"/#{n}/\">" }
          dirs.each do |name|
            it { is_expected.to include(name) }
          end
        end
      end
    end
  end
end
