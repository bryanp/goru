# frozen_string_literal: true

require_relative "../lib/goru/scheduler"

routines = []
scheduler = Goru::Scheduler.new
routines << scheduler.go { |routine| routine.finished(true) }
routines << scheduler.go { |routine| routine.finished(false) }
routines << scheduler.go { |routine| routine.finished(true) }
scheduler.wait

pp routines.map(&:result)
