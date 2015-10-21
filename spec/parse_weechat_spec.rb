# spec/parse_weechat_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_log_converter"
require "jekyll/rp_logs/parse_weechat"

module Jekyll
  module RpLogs
    RSpec.describe WeechatParser do
      subject { WeechatParser }
      it "adds itself to RpLogGenerator's list of parsers" do
        expect(RpLogGenerator.parsers).to include(subject::FORMAT_STR => subject)
      end

      let(:emote_line) { "2015-07-08 01:55:01\t *\tAlice lorem ipsum dolor sit amet, consectetur adipisicing elit. Sequi voluptatibus, quis ratione sit porro vitae, placeat, quos rem quaerat autem voluptates tempore officiis praesentium ipsum distinctio tempora voluptatum veritatis unde." }
      let(:quit_line)  { "2015-07-08 01:56:02\t<--\tAlice (Alice@my.cool.vhost) has quit (Quit: Leaving)" }
      let(:nick_line)  { "2015-07-08 01:57:03\t--\tBob is now known as Carol" }
      let(:text_line)  { "2015-07-08 02:00:04\tAlice\there's a text line" }
      let(:text_mode_line)  { "2015-07-08 02:00:04\t@Alice\there's a text line" }
      let(:unmatched)  { "lorem" }

      describe ".parse_line" do
        it "parses /quit as junk" do
          expect(subject.parse_line quit_line).to be_nil
        end
        it "parses /nick as junk" do
          expect(subject.parse_line nick_line).to be_nil
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
