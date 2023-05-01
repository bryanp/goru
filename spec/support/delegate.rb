# frozen_string_literal: true

require "llhttp"

class Delegate < LLHttp::Delegate
  def initialize
    reset
  end

  def reset
    @message_complete = false
  end

  def message_complete?
    @message_complete == true
  end

  def on_message_complete
    @message_complete = true
  end
end
