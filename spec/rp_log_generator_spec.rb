# spec/rp_log_generator_spec.rb
require "jekyll"
# This will require all the parsers for us
require "jekyll/rp_logs"
require "jekyll/rp_logs/rp_log_converter"

require "rake"
require "yaml"

module Jekyll
  module RpLogs
    # Pretty sure this is gross

    # Rake will eat the ARGV otherwise
    # https://github.com/jimweirich/rake/issues/277
    # Perhaps it doesn't exactly "eat" it but still, it shouldn't think that
    # rspec's command line arguments are its own
    orig_argv = ARGV.dup
    ARGV.replace([])
    Rake.application.init
    ARGV.replace(orig_argv)

    Rake.application.load_rakefile
    Rake.application.options.verbose = false
    Rake::Task["deploy"].invoke

    Dir.chdir("dev_site") do
      DEFAULT_CONFIGURATION = Jekyll::Configuration::DEFAULTS.merge(
        "source" => "./").merge YAML.load_file("_config.yml")
    end

    RSpec.describe RpLogGenerator do
      let(:site) do
        Dir.chdir("dev_site") do
          site = Jekyll::Site.new(DEFAULT_CONFIGURATION)
          site.read
          # puts site.collections[RpLogGenerator::RP_KEY].inspect
          site
        end
      end

      let(:generator) { RpLogGenerator.new(DEFAULT_CONFIGURATION) }

      let(:rp_basenames) do
        site.collections[RpLogGenerator::RP_KEY].docs.map(&:basename_without_ext)
      end

      describe "site" do
        let(:test_names) do
          %w(test test_arc_name test_extension test_format_does_not_exist
             test_infer_char_tags test_no_format test_no_match
             test_nonlist_arc_name)
        end

        context "when initialized" do
          it "has all test files before .generate" do
            expect(rp_basenames).to match_array(test_names)
          end
        end
      end

      describe ".generate" do
        subject do
          generator.generate(site)
          rp_basenames
        end

        it { is_expected.to include("test") }
        it { is_expected.to include("test_arc_name") }
        it { is_expected.to include("test_extension") }
        it { is_expected.to include("test_infer_char_tags") }
        it { is_expected.not_to include("test_format_does_not_exist") }
        it { is_expected.not_to include("test_no_format") }
        it { is_expected.not_to include("test_no_Match") }
        it { is_expected.not_to include("test_nonlist_arc_name") }
      end
    end
  end
end
