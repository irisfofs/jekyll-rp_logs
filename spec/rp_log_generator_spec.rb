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
          # puts site.collections[RpLogGenerator.rp_key].inspect
          site
        end
      end

      # this needs to happen first just so that the log level is overridable
      let!(:generator) do
        # Hide the plugin loaded message
        Jekyll.logger.log_level = :warn
        RpLogGenerator.new(DEFAULT_CONFIGURATION)
      end

      let(:rp_basenames) do
        site.collections[RpLogGenerator.rp_key].docs.map(&:basename_without_ext)
      end

      describe "site" do
        let(:test_names) do
          %w(test test_arc_name test_extension test_format_does_not_exist
             test_infer_char_tags test_no_format test_no_match
             test_nonlist_arc_name test_options
             test_mirc test_skype12 test_skype24)
        end

        context "when initialized" do
          it "has all test files before .generate" do
            expect(rp_basenames).to match_array(test_names)
          end
        end
      end

      describe "site RP collection docs after .generate" do
        subject do
          Jekyll.logger.log_level = :error
          generator.generate(site)
          rp_basenames
        end

        it { is_expected.to include("test") }
        it { is_expected.to include("test_arc_name") }
        it { is_expected.to include("test_extension") }
        it { is_expected.to include("test_infer_char_tags") }
        it { is_expected.to include("test_options") }
        it { is_expected.to include("test_mirc") }
        it { is_expected.to include("test_skype12") }
        it { is_expected.to include("test_skype24") }
        it { is_expected.not_to include("test_format_does_not_exist") }
        it { is_expected.not_to include("test_no_format") }
        it { is_expected.not_to include("test_no_match") }
        it { is_expected.not_to include("test_nonlist_arc_name") }
      end

      describe ".generate's informational messages" do
        context "to stdout" do
          subject do
            Jekyll.logger.log_level = :info
            capture_stdout { capture_stderr { generator.generate(site) } }
          end

          it { is_expected.to include("Converted test.md") }
          it { is_expected.to include("Converted test_arc_name.md") }
          it { is_expected.to include("Converted test_extension.log") }
          it { is_expected.to include("Converted test_infer_char_tags.md") }
          it { is_expected.to include("Converted test_options.md") }
          it { is_expected.to include("Converted test_mirc.md") }
          it { is_expected.to include("Converted test_skype12.md") }
          it { is_expected.to include("Converted test_skype24.md") }
        end

        context "to stderr" do
          subject do
            Jekyll.logger.log_level = :warn
            capture_stderr { generator.generate(site) }
          end

          it { is_expected.to include("Skipping test_format_does_not_exist.md") }
          it { is_expected.to include("Skipping test_no_format.md") }
          it { is_expected.to include("Skipping test_nonlist_arc_name.md") }
          it { is_expected.to include("Skipping test_no_match.md") }
        end
      end

      describe "page.options" do
        context "when parsed" do
          subject do
            RpLogs::Page.new(
              site.collections[RpLogGenerator.rp_key].docs
                .find { |p| p.basename_without_ext == "test_options" }
            ).options
          end

          it { is_expected.to include(strict_ooc: true) }
          it { is_expected.to include(merge_text_into_rp: ["Alice"]) }
          it { is_expected.to include(splits_by_character: ["Bob"]) }
        end
      end

      describe ".initialize" do
        context "when called" do
          describe "LogLine" do
            before do
              logline_config = DEFAULT_CONFIGURATION.merge(
                "ooc_start_delimiters" => "abc",
                "max_seconds_between_posts" => 5
              )
              Jekyll.logger.log_level = :warn
              RpLogGenerator.new(logline_config)
            end

            it "gets max_seconds_between_posts from config file" do
              expect(LogLine.max_seconds_between_posts).to eql(5)
            end
            it "gets ooc_start_delimiters from config file" do
              expect(LogLine.ooc_start_delimiters).to eql("abc")
            end

            after do
              # Restore the default configuration. Very important
              RpLogGenerator.new(DEFAULT_CONFIGURATION)
            end
          end

          describe "RpLogGenerator" do
            let(:diff_key_generator) do
              logline_config = DEFAULT_CONFIGURATION.merge(
                "collections" => { "lorem" => { "output" => true } }
              )
              Jekyll.logger.log_level = :warn
              RpLogGenerator.new(logline_config)
            end

            it "gets default rp_key from default config file" do
              expect(generator.class.rp_key).to eql("rps")
            end
            it "gets rp_key from config file" do
              expect(diff_key_generator.class.rp_key).to eql("lorem")
            end

            after do
              RpLogGenerator.new(DEFAULT_CONFIGURATION)
            end
          end
        end
      end
    end
  end
end
