require File.dirname(__FILE__) + '/../test_helper'
require 'activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application_processor'

class ThesisMessageProcessorProcessorTest < Test::Unit::TestCase
  include ActiveMessaging::TestHelper
  
  def setup
    load File.dirname(__FILE__) + "/../../app/processors/thesis_message_processor_processor.rb"
    @processor = ThesisMessageProcessorProcessor.new
  end
  
  def teardown
    @processor = nil
  end  

  def test_thesis_message_processor_processor
    @processor.on_message('Your test message here!')
  end
end