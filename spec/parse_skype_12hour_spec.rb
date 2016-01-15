# spec/parse_skype_12hour_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_log_converter"
require "jekyll/rp_logs/parsers/skype_12hour"

module Jekyll
  module RpLogs
    RSpec.describe Skype12Parser do
      subject { Skype12Parser }
      it "adds itself to RpLogGenerator's list of parsers" do
        expect(RpLogGenerator.parsers).to include(subject::FORMAT_STR => subject)
      end

      let(:emote_line) { "[6/16/2015 4:48:59 PM] Bob: Bob Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur." }
      let(:text_line)  { "[6/17/2015 7:43:26 PM] Alice: (Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.)" }
      let(:text_line_2)  { "[6/17/2015 8:24:39 PM] Alice: Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." }
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
