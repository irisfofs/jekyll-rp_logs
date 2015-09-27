# spec/rp_parser_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_parser"

module Jekyll
  module RpLogs
    RSpec.describe Parser::LogLine do
      before do
        @alice_line = Parser::LogLine.new(
          DateTime.new(2015, 9, 23, 14, 35, 27, "-4"),
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
      before :context do
        @timestamp = DateTime.new(2015, 9, 23, 14, 35, 27, "-4")
        @rp_contents = "Lorem ipsum dolor sit amet, consectetur adipisicing elit."
        @ooc_contents = "(Lorem ipsum dolor sit amet, consectetur adipisicing elit.)"
      end
      let(:rp_line) do
        Parser::LogLine.new(@timestamp, sender: "Alice", contents: @rp_contents, flags: "", type: :rp)
      end
      let(:ooc_line) do
        Parser::LogLine.new(@timestamp, sender: "Alice", contents: @ooc_contents, flags: "", type: :ooc)
      end
      let(:rp_flag) do
        Parser::LogLine.new(@timestamp, sender: "Alice", contents: @ooc_contents, flags: "!RP", type: :ooc)
      end
      let(:ooc_flag) do
        Parser::LogLine.new(@timestamp, sender: "Alice", contents: @rp_contents, flags: "!OOC", type: :rp)
      end
      let(:invalid_type) do
        Parser::LogLine.new(@timestamp, sender: "Alice", contents: " ", flags: "", type: :not_a_type)
      end

      describe ".output_type" do
        context "with :strict_ooc option" do
          let(:strict_ooc_default) do
            Parser::LogLine.new(@timestamp, { strict_ooc: true }, sender: "Alice", contents: @rp_contents, flags: "", type: :ooc)
          end
          let(:strict_ooc_ooc) do
            Parser::LogLine.new(@timestamp, { strict_ooc: true }, sender: "Alice", contents: @ooc_contents, flags: "", type: :ooc)
          end

          it "is RP without open paren" do
            expect(strict_ooc_default.output_type).to eql(:rp)
          end
          it "is OOC with open paren" do
            expect(strict_ooc_ooc.output_type).to eql(:ooc)
          end

          context "with flags" do
            let(:strict_rp_flag) do
              Parser::LogLine.new(@timestamp, { strict_ooc: true }, sender: "Alice", contents: @ooc_contents, flags: "!RP", type: :ooc)
            end
            let(:strict_ooc_flag) do
              Parser::LogLine.new(@timestamp, { strict_ooc: true }, sender: "Alice", contents: @rp_contents, flags: "!OOC", type: :rp)
            end

            it "is RP with !RP flag" do
              expect(strict_rp_flag.output_type).to eql(:rp)
            end
            it "is OOC with !OOC flag" do
              expect(strict_ooc_flag.output_type).to eql(:ooc)
            end
          end
        end

        context "without :strict_ooc option" do
          it "is RP when originally RP" do
            expect(rp_line.output_type).to eql(:rp)
          end
          it "is OOC when originally OOC" do
            expect(ooc_line.output_type).to eql(:ooc)
          end
          it "is RP with !RP flag" do
            expect(rp_flag.output_type).to eql(:rp)
          end
          it "is OOC with !OOC flag" do
            expect(ooc_flag.output_type).to eql(:ooc)
          end
        end
      end

      describe ".output_timestamp" do
        # This feels like a bad test :S
        it "combines anchor, title, and display" do
          expect(rp_line.output_timestamp).to eql("<a name=\"#{@timestamp.strftime('%Y-%m-%d_%H:%M:%S')}\" title=\"#{@timestamp.strftime('%H:%M:%S %B %-d, %Y')}\" href=\"##{@timestamp.strftime('%Y-%m-%d_%H:%M:%S')}\">#{@timestamp.strftime('%H:%M')}</a>")
        end
      end

      describe ".output_sender" do
        it "diplays RP senders correctly" do
          expect(rp_line.output_sender).to eql("  * Alice")
          expect(ooc_flag.output_sender).to eql("  * Alice")
        end
        it "displays OOC senders correctly" do
          expect(ooc_line.output_sender).to eql(" &lt; Alice&gt;")
          expect(rp_flag.output_sender).to eql(" &lt; Alice&gt;")
        end
        context "when given a nonexistent base_type" do
          it "raises a 'No known type' error" do
            expect { invalid_type.output_sender }.to raise_exception("No known type: not_a_type")
          end
        end
      end

      describe ".output_tags" do
        it "outputs .rp when given RP output type" do
          expect(rp_line.output_tags).to eql(['<p class="rp">', "</p>"])
        end
        it "outputs .ooc when given OOC output type" do
          expect(ooc_line.output_tags).to eql(['<p class="ooc">', "</p>"])
        end
        context "when given a nonexistent output_type" do
          it "raises a 'No known type' error" do
            expect { invalid_type.output_tags }.to raise_exception("No known type: not_a_type")
          end
        end
      end
    end
  end
end
