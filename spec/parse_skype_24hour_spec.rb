# spec/parse_skype_24hour_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_log_converter"
require "jekyll/rp_logs/parsers/skype_24hour"

module Jekyll
  module RpLogs
    RSpec.describe Skype24Parser do
      subject { Skype24Parser }
      it "adds itself to RpLogGenerator's list of parsers" do
        expect(RpLogGenerator.parsers).to include(subject::FORMAT_STR => subject)
      end

      let(:emote_line) { "[05.06.15 12:24:18] Bob: Bob Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." }
      let(:text_line)  { "[05.06.15 20:34:19] Bob: (Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat)" }
      let(:text_line_2)  { "[05.06.15 20:34:56] Alice: Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur." }
      let(:unmatched)  { "lorem" }

      describe ".parse_line" do
        it "parses /me as RP" do
          expect(subject.parse_line(emote_line).base_type).to be :rp
        end
        it "parses text as OOC" do
          expect(subject.parse_line(text_line).base_type).to be :ooc
        end
        it "parses text without parens as OOC" do
          expect(subject.parse_line(text_line_2).base_type).to be :ooc
        end
        it "parses an unmatched line as nil" do
          expect(subject.parse_line unmatched).to be_nil
        end
      end
    end
  end
end
