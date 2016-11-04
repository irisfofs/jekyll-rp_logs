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
    RSpec.describe "After building the site" do
      DEFAULT_CONFIGURATION = Util.gross_setup_stuff

      before(:all) do
        Dir.chdir("dev_site") do
          site = Jekyll::Site.new(DEFAULT_CONFIGURATION)
          capture_stderr { capture_stdout { site.process } }
        end
      end

      describe "the index page html" do
        subject { File.read(File.join("dev_site", "_site", "index.html")) }

        # Each one should be linked in the file somewhere
        dirs = Util::VALID_TEST_NAMES.map { |n| "href=\"./#{n}/\">" }
        dirs.each do |name|
          it { is_expected.to include(name) }
        end
        it { is_expected.to include("a title='Some Description Here' href=") }
      end

      describe "the tag descriptions" do
        desc_map = { "Alice" => "Have some words", "test" => "More words" }

        desc_map.each_pair do |tag, desc|
          context "for tag #{tag}" do
            fn = File.join("dev_site", "_site", "tags", tag, "index.html")
            it "have the description \"#{desc}\"" do
              expect(File.read(fn)).to include(desc)
            end
          end
        end
      end

      describe "a rendered RP" do
        let(:content) do
          fn = File.join("dev_site", "_site", "test", "index.html")
          File.open(fn) { |f| Nokogiri::HTML(f) }
        end

        let(:rp_a) { content.at_css("p.rp > a") }
        let(:ooc_a) { content.at_css("p.ooc > a") }
        let(:rp_flag_a) { content.at_css("p:nth-child(4) > a") }
        let(:ooc_flag_a) { content.at_css("p:nth-child(5) > a") }
        let(:special_chars) { content.at_css("p:nth-child(6) > a").next_sibling }

        let(:rp_text) { rp_a.next_sibling }
        let(:ooc_text) { ooc_a.next_sibling }
        let(:ooc_flag_text) { ooc_flag_a.next_sibling }
        let(:rp_flag_text) { rp_flag_a.next_sibling }

        it "has the correct timestamp attributes" do
          name = "2015-07-08_01:55:00"
          title = "01:55:00 July 8, 2015"
          expect(rp_a.attributes["name"].value).to eq name
          expect(rp_a.attributes["title"].value).to eq title
          expect(rp_a.attributes["href"].value).to eq "##{name}"
        end

        it "has the right text" do
          # rubocop:disable Metrics/LineLength
          text = "Alice lorem ipsum dolor sit amet, consectetur adipisicing elit. Sequi voluptatibus, quis ratione sit porro vitae, placeat, quos rem quaerat autem voluptates tempore officiis praesentium ipsum distinctio tempora voluptatum veritatis unde."
          # rubocop:enable Metrics/LineLength
          expect(rp_text.text.rstrip).to eq text
        end

        it "formats RP senders correctly" do
          expect(rp_text.text).to start_with("Alice")
          expect(ooc_flag_text.text).to start_with("Alice")
        end

        it "formats OOC senders correctly" do
          expect(ooc_text.to_s).to start_with("&lt;@Alice&gt;")
          expect(rp_flag_text.to_s).to start_with("&lt;@Alice&gt;")
        end

        it "gives RP the .rp class" do
          expect(content.at_css("p.rp")).to_not be_nil
        end

        it "gives OOC the .ooc class" do
          expect(content.at_css("p.ooc")).to_not be_nil
        end

        it "escapes HTML entities" do
          expect(special_chars.to_s).to start_with(
            "&lt;@Alice&gt; Escaped characters: Foo &amp; Bar \"baz\" &lt;horse&gt;")
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
