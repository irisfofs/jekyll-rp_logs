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

    RSpec.describe "Integration Tests" do
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

        describe "the tag description" do
          desc_map = { "Alice" => "Have some words", "test" => "More words" }

          desc_map.each_pair do |tag, desc|
            context "for tag #{tag}" do
              fn = File.join("dev_site", "_site", "tags", tag, "index.html")
              it "has the description \"#{desc}\"" do
                expect(File.read(fn)).to include(desc)
              end
            end
          end
        end
      end

      describe "the existing rp pages" do
        subject { Dir.glob("dev_site/_site/*") }

        Util::VALID_TEST_NAMES.map { |n| "dev_site/_site/#{n}" }.each do |name|
          it { is_expected.to include(name) }
        end
      end

      describe "the existing tag pages" do
        subject { Dir.glob("dev_site/_site/tags/*") }

        Util::EXISTING_TAGS.map { |t| "dev_site/_site/tags/#{t}" }.each do |tag|
          it { is_expected.to include(tag) }
        end
      end
    end
  end
end
