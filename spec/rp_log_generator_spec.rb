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
          site.reset
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

      valid_test_names =
        %w(test test_arc_name test_extension test_infer_char_tags test_options
           test_disable_liquid test_tag_implication
           test_mirc test_skype12 test_skype24).freeze

      skipped_test_names =
        %w(test_format_does_not_exist test_no_format test_no_match
           test_nonlist_arc_name).freeze

      describe "site" do
        context "when initialized" do
          it "has all test files before .generate" do
            expect(rp_basenames).to match_array(valid_test_names + skipped_test_names)
          end
        end

        describe "#render" do
          subject do
            Jekyll.logger.log_level = :error
            generator.generate(site)
            # Needs to be exactly around this to get the dir right
            Dir.chdir("dev_site") do
              site.render
            end
          end

          it "does not try to parse Liquid tags" do
            expect { subject }.to_not raise_error
          end
        end
      end

      describe "#generate" do
        describe "keeps and removes the right RPs from the collection" do
          subject do
            Jekyll.logger.log_level = :error
            generator.generate(site)
            rp_basenames
          end

          valid_test_names.each { |fn| it { is_expected.to include(fn) } }
          skipped_test_names.each { |fn| it { is_expected.not_to include(fn) } }
        end

        subject do
          Jekyll.logger.log_level = :error
          generator.generate(site)
          RpLogs::Page.new(site.collections[RpLogGenerator.rp_key].docs
            .find { |rp| rp.basename_without_ext == "test_tag_implication" }
          )
        end

        it "infers character tags from posts" do
          expect(subject.tag_strings).to include("char:Alice")
        end
        it "performs tag implication and aliasing" do
          expect(subject.tag_strings).to match_array(
            %w(test char:John char:Alice lorem\ ipsum dolor sit\ amet noncanon))
        end
      end

      describe "#generate's informational messages" do
        context "to stdout" do
          subject do
            Jekyll.logger.log_level = :debug
            capture_stdout { capture_stderr { generator.generate(site) } }
          end

          valid_test_names.each { |fn| it { is_expected.to include("Converted #{fn}") } }
          it { is_expected.to include("#{valid_test_names.size} RPs converted") }
        end

        context "to stderr" do
          subject do
            Jekyll.logger.log_level = :warn
            capture_stderr { generator.generate(site) }
          end

          skipped_test_names.each { |fn| it { is_expected.to include("Skipping #{fn}") } }
        end
      end

      describe "page#options" do
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

      describe "#initialize" do
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
