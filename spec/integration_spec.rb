# spec/integration_spec.rb
require "jekyll"
# This will require all the parsers for us
require "jekyll/rp_logs"
require "jekyll/rp_logs/rp_log_converter"

require "nokogiri"
require "rake"
require "yaml"

# Pull in some gross setup stuff for rakefiles
require_relative "util"

module Jekyll
  module RpLogs
    RSpec.describe "Integration Tests" do
      DEFAULT_CONFIGURATION = Util.gross_setup_stuff

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

        describe "a rendered RP" do
          subject do
            fn = File.join("dev_site", "_site", "test_disable_liquid", "index.html")
            content = File.open(fn) { |f| Nokogiri::HTML(f) }
            content.at_css("p.rp > a")
          end

          it "has the correct timestamp attributes" do
            name = "2015-07-08_01:55:00"
            title = "01:55:00 July 8, 2015"
            expect(subject.attributes["name"].value).to eq name
            expect(subject.attributes["title"].value).to eq title
            expect(subject.attributes["href"].value).to eq "##{name}"
          end

          it "has the right text" do
            text = "  * Alice lorem ipsum dolor sit amet, consectetur adipisicing elit. Sequi voluptatibus, quis ratione sit porro vitae, placeat, quos rem quaerat autem voluptates tempore officiis praesentium ipsum distinctio tempora voluptatum veritatis unde."
            expect(subject.next_sibling.text).to eq text
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
