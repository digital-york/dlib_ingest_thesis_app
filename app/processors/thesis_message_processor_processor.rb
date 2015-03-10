class ThesisMessageProcessorProcessor < ApplicationProcessor

  subscribes_to :thesis_message_processor

  def on_message(message)
    logger.debug "ThesisMessageProcessorProcessor received: " + message
  end
end