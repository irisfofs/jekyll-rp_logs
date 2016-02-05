# spec/rp_tags_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_page"

module Jekyll
  module RpLogs
    RSpec.describe Tag do
      describe ".initialize" do
        context "when given names with unsafe URL characters" do
          unsafe_tags =
            { "horse's" => "horse_s",
              '"quote"' => "_quote_",
              "☃" => "_" }

          it "strips spaces" do
            expect(Tag.new("a space").dir).to eql("a_space")
          end
          it "strips other characters" do
            unsafe_tags.each do |tag, stripped|
              expect(Tag.new(tag).dir).to eql(stripped)
            end
          end
          it "doesn't affect the tag name" do
            unsafe_tags.each do |tag, _|
              expect(Tag.new(tag).name).to eql(tag)
            end
          end
        end
      end

      describe "#<=>" do
        # Examples from both sides of the alphabet, to show that ordering
        # isn't just alphabetical
        let(:meta_safe) { Tag.new("safe") }
        let(:meta_complete) { Tag.new("complete") }
        let(:g_aardvark) { Tag.new("aardvark") }
        let(:g_zebra) { Tag.new("zebra") }
        let(:char_zom) { Tag.new("char:Zom") }
        let(:char_alice) { Tag.new("char:Alice") }

        describe Tag.new "char:George" do
          it { is_expected.to be < g_zebra }
          it { is_expected.to be < g_aardvark }
          it { is_expected.to be < meta_safe }
          it { is_expected.to be < meta_complete }
          it { is_expected.to be < char_zom }
          it { is_expected.to be > char_alice }
        end

        describe Tag.new "incomplete" do
          it { is_expected.to be < g_zebra }
          it { is_expected.to be < g_aardvark }
          it { is_expected.to be < meta_safe }
          it { is_expected.to be > meta_complete }
          it { is_expected.to be > char_zom }
          it { is_expected.to be > char_alice }
        end

        describe Tag.new "normal" do
          it { is_expected.to be < g_zebra }
          it { is_expected.to be > g_aardvark }
          it { is_expected.to be > meta_safe }
          it { is_expected.to be > meta_complete }
          it { is_expected.to be > char_zom }
          it { is_expected.to be > char_alice }
        end
      end

      context "when sorted" do
        def to_tags(list)
          list.map { |tag| Tag.new(tag) }
        end

        it "character tags are before regular tags" do
          tag_list = to_tags %w(banana aardvark wet water char:Eve)
          sorted   = to_tags %w(char:Eve aardvark banana water wet)
          expect(tag_list.sort).to eql(sorted)
        end

        it "meta tags are before regular tags" do
          tag_list = to_tags %w(a questionable horse doing safe things)
          sorted   = to_tags %w(questionable safe a doing horse things)
          expect(tag_list.sort).to eql(sorted)
        end

        it "character tags are before meta tags" do
          tag_list = to_tags %w(incomplete char:Alice char:Wilfred complete)
          sorted   = to_tags %w(char:Alice char:Wilfred complete incomplete)
          expect(tag_list.sort).to eql(sorted)
        end

        it "character tags, then meta tags, then regular tags" do
          tag_list = to_tags %w(while char:Bob buys safe things char:Alice finds them
                                incomplete but char:Watson likes the explicit stuff)
          sorted   = to_tags %w(char:Alice char:Bob char:Watson explicit incomplete safe
                                but buys finds likes stuff the them things while)
          expect(tag_list.sort).to eql(sorted)
        end
      end
    end
  end
end
