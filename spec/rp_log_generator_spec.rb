# spec/rp_log_generator_spec.rb
require "jekyll"
# This will require all the parsers for us
require "jekyll/rp_logs"
require "jekyll/rp_logs/rp_log_converter"

require "rake"
require "yaml"

require_relative "util"

module Jekyll
  module RpLogs
    DEFAULT_CONFIGURATION = Util.gross_setup_stuff

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

      valid_test_names = Util::VALID_TEST_NAMES

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
          RpLogs::Page.new(
            site.collections[RpLogGenerator.rp_key].docs
              .find { |rp| rp.basename_without_ext == "test_tag_implication" }
          )
        end

        it "infers character tags from posts" do
          expect(subject.tag_strings).to include("char:Alice")
        end
        it "performs tag implication and aliasing" do
          expect(subject.tag_strings).to match_array(
            %w(test char:John char:Alice lorem\ ipsum dolor sit\ amet noncanon
               "developer's\ quote\ test"))
        end

        context "when infer_char_tags is disabled" do
          subject do
            Jekyll.logger.log_level = :error
            generator.generate(site)
            RpLogs::Page.new(
              site.collections[RpLogGenerator.rp_key].docs
                .find { |rp| rp.basename_without_ext == "test_infer_char_tags" }
            )
          end

          it "doesn't infer character tags" do
            expect(subject.tag_strings).not_to include("char:Alice")
            expect(subject.tag_strings).not_to include("char:Bob")
          end
          it "still performs tag implication and aliasing" do
            expect(subject.tag_strings).to include("dolor")
            expect(subject.tag_strings).to include("sit amet")
          end
        end

        def remove_one
          site.pages.delete_if &Proc.new # block condition
          generator.generate(site)
        end

        context "when missing main index.html" do
          subject { remove_one { |p| p.data["rp_index"] } }

          it "logs error message" do
            expect do
              begin subject
              rescue SystemExit # Suppress it so we can check output value
              end
            end.to output(/Main index page missing/).to_stderr
          end

          it "aborts" do
            expect { capture_stderr { subject } }.to raise_error SystemExit
          end
        end

        context "when missing arc index.html" do
          subject { remove_one { |p| p.data["rp_arcs"] } }

          it "logs error message" do
            expect do
              begin subject
              rescue SystemExit # Suppress it so we can check output value
              end
            end.to output(/Arc index page missing/).to_stderr
          end

          it "aborts" do
            expect { capture_stderr { subject } }.to raise_error SystemExit
          end
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
