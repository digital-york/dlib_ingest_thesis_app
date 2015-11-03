#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor
  # change the queue name to match the server
  
  s.destination :thesis_message_processor, '/queue/ThesisMessageProcessor'
  s.queue :workflow_queue, 'yodldev1.genericworkflow.messages'
end
