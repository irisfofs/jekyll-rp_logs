# spec/rp_parser_spec.rb
require "jekyll"
require "jekyll/rp_logs/rp_arcs"

module Jekyll
  module RpLogs
    RSpec.describe Arc do
      let(:rp_2015) do
        rp = double("rp_2015")
        data_hash = { "start_date" => Date.parse("2015-09-24"),
                      "last_post_time" => Date.parse("2015-09-25") }
        allow(rp).to receive(:data).and_return(data_hash)
        rp
      end

      let(:rp_2015_adjusted) do
        rp = double("rp_2015_adjusted")
        data_hash = { "time_line" => Date.parse("2014-01-01"),
                      "start_date" => Date.parse("2015-05-12"),
                      "last_post_time" => Date.parse("2015-05-12") }
        allow(rp).to receive(:data).and_return(data_hash)
        rp
      end

      let(:rp_2014) do
        rp = double("rp_2014")
        data_hash = { "start_date" => Date.parse("2014-02-15"),
                      "last_post_time" => Date.parse("2014-02-16") }
        allow(rp).to receive(:data).and_return(data_hash)
        rp
      end

      let(:rps) do
        [rp_2015_adjusted, rp_2015, rp_2014]
      end

      let(:lorem_arc) do
        a = Arc.new("Lorem Ipsum")
        a.rps = rps
        a
      end

      let(:lorem_arc_deep_copy) do
        a = Arc.new("Lorem Ipsum")
        a.rps = rps
        a
      end

      let(:no_time_line_arc) do
        a = Arc.new("Turquoise Shoe")
        a << rp_2015 << rp_2014
        a
      end

      let(:lorem_arc_no_rps) do
        Arc.new("Lorem Ipsum")
      end


      describe "attributes" do
        subject { lorem_arc }

        it { is_expected.to respond_to(:name) }
        it { is_expected.to respond_to(:rps) }
        it { is_expected.to respond_to(:<<) }
        it "is an arc" do
          expect(lorem_arc.arc?).to be_truthy
        end
        it { is_expected.to respond_to(:to_s) }
        it { is_expected.to respond_to(:hash) }
        it { is_expected.to respond_to(:<=>) }
        it { is_expected.to respond_to(:inspect) }
        it { is_expected.to respond_to(:to_liquid) }
      end

      describe ".rps" do
        it "returns all rps" do
          expect(lorem_arc.rps).to eql(rps)
        end
      end

      describe ".start_date" do
        it "checks time_line values" do
          expect(lorem_arc.start_date).to eql(rp_2015_adjusted.data["time_line"])
        end
        it "returns first start_date" do
          expect(no_time_line_arc.start_date).to eql(rp_2014.data["start_date"])
        end
      end

      describe ".end_date" do
        it "returns last end date" do
          expect(lorem_arc.end_date).to eql(rp_2015.data["last_post_time"])
        end
      end

      describe ".to_s" do
        it "returns the name of the arc" do
          expect(lorem_arc.to_s).to eql("Lorem Ipsum")
        end
      end

      describe ".hash" do
        it "returns the hash of the name of the arc" do
          expect(lorem_arc.hash).to eql("Lorem Ipsum".hash)
        end
      end

      describe ".eql?" do
        it "returns true on a deep copy" do
          expect(lorem_arc).to eql(lorem_arc_deep_copy)
        end
        it "returns false when RPs don't match" do
          expect(lorem_arc).not_to eql(lorem_arc_no_rps)
        end
      end

      describe ".<=>" do
        it "returns nil for class mismatches" do
          expect(lorem_arc <=> 5).to be_nil
        end
        it "compares the name" do
          expect(lorem_arc).to be < no_time_line_arc
          expect(no_time_line_arc).to be > lorem_arc
        end
      end

      describe ".inspect" do
        it "returns a string" do
          expect(lorem_arc.inspect).to be_kind_of String
        end
      end

      describe ".to_liquid" do
        it "returns a hash" do
          expect(lorem_arc.to_liquid).to be_kind_of Hash
        end
      end
    end
  end
end
