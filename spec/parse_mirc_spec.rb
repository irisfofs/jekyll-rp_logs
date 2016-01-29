# spec/parse_mirc_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_log_converter"
require "jekyll/rp_logs/parsers/mirc"

module Jekyll
  module RpLogs
    RSpec.describe MIRCParser do
      subject { MIRCParser }
      it "adds itself to RpLogGenerator's list of parsers" do
        expect(RpLogGenerator.parsers).to include(subject::FORMAT_STR => subject)
      end

      # rubocop:disable Metrics/LineLength
      let(:emote_line) { "06 11 15[22:14] * Alice Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." }
      let(:join_line)  { "0306 14 15[18:52] * Test (664@244-224-824-22-dolar.sit) has joined #omnis" }
      let(:text_line)  { "06 14 15[18:54] <Alice> (Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.)" }
      let(:text_mode_line) { "06 14 15[18:54] <@Alice> (Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.)" }
      let(:unmatched) { "lorem" }
      # rubocop:enable Metrics/LineLength

      describe ".parse_line" do
        it "parses /join as junk" do
          expect(subject.parse_line join_line).to be_nil
        end
        it "parses /me as RP" do
          expect(subject.parse_line(emote_line).base_type).to be :rp
        end
        it "parses text as OOC" do
          expect(subject.parse_line(text_line).base_type).to be :ooc
        end
        it "parses text (with mode char) as OOC" do
          expect(subject.parse_line(text_mode_line).base_type).to be :ooc
        end
        it "parses an unmatched line as nil" do
          expect(subject.parse_line unmatched).to be_nil
        end
      end
    end
  end
end
