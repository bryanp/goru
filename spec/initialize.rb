# frozen_string_literal: true

require "pathname"

initializers = Pathname.new(File.expand_path("../initializers", __FILE__))

if initializers.directory?
  initializers.glob("*.rb") do |file|
    load(file)
  end
end
