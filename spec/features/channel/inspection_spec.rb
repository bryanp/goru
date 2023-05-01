# frozen_string_literal: true

require "goru/scheduler"

RSpec.describe "inspecting a channel" do
  let(:channel) {
    Goru::Channel.new
  }

  describe "#any?" do
    it "returns true if the channel has values" do
      channel << :foo

      expect(channel.any?).to eq(true)
    end

    it "returns false if the channel does not have values" do
      expect(channel.any?).to eq(false)
    end
  end

  describe "#empty?" do
    it "returns false if the channel has values" do
      channel << :foo

      expect(channel.empty?).to eq(false)
    end

    it "returns true if the channel does not have values" do
      expect(channel.empty?).to eq(true)
    end
  end

  describe "#full?" do
    it "returns false" do
      expect(channel.full?).to eq(false)
    end

    context "channel has a defined size" do
      let(:channel) {
        Goru::Channel.new(size: 3)
      }

      it "returns false if the channel still has space" do
        expect(channel.full?).to eq(false)

        channel << :foo

        expect(channel.full?).to eq(false)

        channel << :bar

        expect(channel.full?).to eq(false)
      end

      it "returns true if the channel is full" do
        channel << :foo
        channel << :bar
        channel << :baz

        expect(channel.full?).to eq(true)
      end
    end
  end

  describe "#length" do
    it "returns the number of values" do
      expect {
        channel << :foo
      }.to change {
        channel.length
      }.from(0).to(1)
    end
  end
end
