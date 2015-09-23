# spec/rp_parser_spec.rb
require 'jekyll'
require "jekyll/rp_logs/rp_parser"

module Jekyll
  module RpLogs

    RSpec.describe Parser::LogLine do
      before do
        @alice_line = Parser::LogLine.new(
          DateTime.new(2015,9,23,14,35,27,"-4"),
          sender: "Alice",
          contents: "Lorem ipsum dolor sit amet, consectetur adipisicing elit.",
          flags: "",
          type: :rp
        )
      end

      describe "attributes" do
        subject do
          @alice_line
        end

        it { is_expected.to respond_to(:timestamp) }
        it { is_expected.to respond_to(:mode) }
        it { is_expected.to respond_to(:sender) }
        it { is_expected.to respond_to(:contents) }
        it { is_expected.to respond_to(:flags) }
        it { is_expected.to respond_to(:base_type) }
        it { is_expected.to respond_to(:output_type) }

        let(:alice_line) do
          @alice_line
        end

        context "without arguments" do
          describe ".mode" do
            it "returns \" \"" do
              expect(alice_line.mode).to eql(" ")
            end
          end
        end
      end

      # Test the proper classification of lines as RP or OOC for output, based
      # on various properties: the strict_ooc option, beginning with parens, 
      # and any flags specified
      describe "output_type" do
        before do
          @timestamp = DateTime.new(2015,9,23,14,35,27,"-4")
          @rp_contents = "Lorem ipsum dolor sit amet, consectetur adipisicing elit."
          @ooc_contents = "(Lorem ipsum dolor sit amet, consectetur adipisicing elit.)"
        end

        context "with :strict_ooc option" do
          let(:strict_ooc_default) do 
            Parser::LogLine.new(
              @timestamp,
              options = { :strict_ooc => true },
              sender: "Alice",
              contents: @rp_contents,
              flags: "",
              type: :ooc
            )
          end

          let(:strict_ooc_ooc) do 
            Parser::LogLine.new(
              @timestamp,
              options = { :strict_ooc => true },
              sender: "Alice",
              contents: @ooc_contents,
              flags: "",
              type: :ooc
            )
          end

          it "is RP without open paren" do
            expect(strict_ooc_default.output_type).to eql(:rp)
          end
          it "is OOC with open paren" do
            expect(strict_ooc_ooc.output_type).to eql(:ooc)
          end
        end
      end
    end

  end
end