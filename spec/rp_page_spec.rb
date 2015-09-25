# spec/rp_parser_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_page"

module Jekyll
  module RpLogs
    RSpec.describe Page do
      describe "delegations" do
        subject do
          Page.new(nil)
        end

        it { is_expected.to respond_to(:[]) }
        it { is_expected.to respond_to(:[]=) }
        it { is_expected.to respond_to(:content) }
        it { is_expected.to respond_to(:content=) }
        it { is_expected.to respond_to(:path) }
        it { is_expected.to respond_to(:to_liquid) }
      end
    end
  end
end
