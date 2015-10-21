# spec/parse_irssi_xchat_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_log_converter"
require "jekyll/rp_logs/parse_irssi_xchat"

module Jekyll
  module RpLogs
    RSpec.describe IrssiXChatParser do
      subject { IrssiXChatParser }

      it "adds itself to RpLogGenerator's list of parsers" do
        expect(RpLogGenerator.parsers).to include(subject::FORMAT_STR => subject)
      end

      # --- Log opened Fri May 23 01:13:27 2014
      let(:emote_line)     { "01:13                * | Alice lorem ipsum dolor sit amet, consectetur adipisicing elit. Sequi voluptatibus, quis ratione sit porro vitae, placeat, quos rem quaerat autem voluptates tempore officiis praesentium ipsum distinctio tempora voluptatum veritatis unde." }
      let(:text_line)      { "01:15 <         Alice> | regular text line" }
      let(:text_mode_line) { "01:15 <@        Alice> | text with a nick mode character" }
      let(:unmatched)      { "lorem" }

      describe ".parse_line" do
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


