# spec/rp_parser_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_tag_implication_handler"

module Jekyll
  module RpLogs
    RSpec.describe TagImplicationHandler do
      # rubocop:disable Style/WordArray
      let(:implication_set_1) do
        { "tag_implications" =>
            { "apple" => ["fruit", "delicious"],
              "fruit" => ["plant ovary"],
              "banana" => ["fruit", "easy to eat"]
            },
          "tag_aliases" => { "bananana" => ["banana"] }
        }
      end
      # rubocop:enable Style/WordArray

      let(:two_elem_alias_loop) do
        { "tag_implications" => {},
          "tag_aliases" =>
          { "foo" => ["bar"],
            "bar" => ["foo"]
          }
        }
      end

      let(:alias_imply_loop) do
        { "tag_implications" => { "b" => ["c"] },
          "tag_aliases" =>
          { "a" => ["b"],
            "c" => ["a"]
          }
        }
      end

      let(:imply_alias_same_target) do
        { "tag_implications" => { "apple" => ["fruit"] },
          "tag_aliases" => { "apple" => ["redfruit"] }
        }
      end

      # rubocop:disable Style/WordArray
      let(:alias_original_tag) do
        { "tag_implications" => {},
          "tag_aliases" => { "apple" => ["apple", "fruit"] }
        }
      end
      # rubocop:enable Style/WordArray

      let(:imply_aliased_tag) do
        { "tag_implications" => { "apple" => ["tasty"] },
          "tag_aliases" => { "tasty" => ["delicious"] }
        }
      end

      let(:imply_aliased_tags) do
        { "tag_implications" => { "apple" => ["tasty", "fruit"] },
          "tag_aliases" =>
          { "tasty" => ["delicious"],
            "fruit" => ["not a fruit"] }
        }
      end

      def expect_extraction(config)
        expect { capture_stderr { TagImplicationHandler.new(config) } }
      end

      # rubocop:disable Style/RescueModifier
      def expect_extraction_output(config)
        expect(capture_stderr { TagImplicationHandler.new(config) rescue nil })
      end
      # rubocop:enable Style/RescueModifier

      describe ".extract_settings" do
        context "when given valid rules" do
          it { expect { TagImplicationHandler.new(implication_set_1) }.to_not raise_error }
        end
        context "when given invalid rules" do
          before do
            @old_level = Jekyll.logger.writer.level
            Jekyll.logger.log_level = :info
          end

          it "detects a 2-item alias loop" do
            expect_extraction(two_elem_alias_loop).to raise_error TagImplicationHandler::TagImplicationError
            expect_extraction_output(two_elem_alias_loop).to include("cycle")
          end
          it "detects an alias-implication loop" do
            expect_extraction(alias_imply_loop).to raise_error TagImplicationHandler::TagImplicationError
            expect_extraction_output(alias_imply_loop).to include("cycle")
          end
          it "does not allow aliases and implications from the same target" do
            expect_extraction(imply_alias_same_target).to raise_error TagImplicationHandler::TagImplicationError
            expect_extraction_output(imply_alias_same_target).to include("both aliased and implied from")
          end
          it "does not allow aliases that include the original tag" do
            expect_extraction(alias_original_tag).to raise_error TagImplicationHandler::TagImplicationError
            expect_extraction_output(alias_original_tag).to include("is equivalent to an implication")
          end
          it "warns when implying an aliased tag" do
            expect_extraction_output(imply_aliased_tag).to include("is an aliased tag.")
          end
          it "warns when implying aliased tags" do
            expect_extraction_output(imply_aliased_tags).to include("are aliased tags.")
          end

          after do
            Jekyll.logger.writer.level = @old_level
          end
        end
      end
    end
  end
end
