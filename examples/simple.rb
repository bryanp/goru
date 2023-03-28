# frozen_string_literal: true

require_relative "../lib/goru"

include Goru

go(:foo) { |routine| 
  routine.finished(true) 
}