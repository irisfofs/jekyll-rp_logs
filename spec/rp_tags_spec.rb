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
    end
  end
end
