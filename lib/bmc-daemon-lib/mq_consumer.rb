require 'time'

module BmcDaemonLib
  class MqConsumerError              < StandardError; end
  class MqConsumerException          < StandardError; end
  class MqConsumerTopicNotFound      < StandardError; end

  class MqConsumer < MqEndpoint
    include LoggerHelper

    def subscribe_to_queue name, context = nil
      log_info "subscribe_to_queue [#{name}]"

      # Queue for this rule
      @queue = @channel.queue(name, auto_delete: false, durable: true)

      # Create consumer on this queue
      @queue.subscribe(manual_ack: AMQP_MANUAL_ACK, on_cancellation: :consumer_cancelled) do |delivery_info, metadata, payload|
        handle_receive context, delivery_info, metadata, payload
      end
    end

    def listen_to topic, rkey
      # puts "listen_to(#{topic},#{rkey})"
      log_info "listen_to [#{topic}] [#{rkey}] > [#{@queue.name}]"
      @queue.bind topic, routing_key: rkey
      # Ensure a queue has been successfully subscribed first
      unless @queue
        error = "listen_to: no active queue (call subscribe_to_queue beforehand)"
        log_error error
        raise MqConsumerException, error
      end

      # Handle errors
      rescue Bunny::NotFound => e
        log_error "exchange not found: #{e.inspect}"
        raise MqConsumerTopicNotFound, e.message

      rescue StandardError => e
        log_error "UNEXPECTED EXCEPTION: #{e.inspect}"
        raise MqConsumerException, e.message
    end
    
  protected

    def handle_receive context, delivery_info, metadata, payload
      # raise MqConsumerError, "testing!"

      # Prepare data
      msg_topic = delivery_info.exchange
      msg_rkey = delivery_info.routing_key.force_encoding('UTF-8')
      msg_tag = delivery_info.delivery_tag
      msg_headers = metadata.headers || {}

      # Extract payload
      msg_data = payload_parse payload, metadata.content_type

      # Announce match
      payload_bytesize = payload.bytesize
      log_message MSG_RECV, msg_topic, msg_rkey, msg_data, {
        app_id:       metadata.app_id,
        sent_at:      msg_headers['sent_at'],
        channel_tag:  "#{@channel.id}.#{msg_tag}",
        content_type: metadata.content_type,
        delay_ms:     extract_delay(msg_headers),
        body_size:    format_bytes(payload_bytesize, "B"),
        }

      # Hand to the callback
      handle_message context, metadata, delivery_info,
        topic: msg_topic,
        rkey: msg_rkey,
        tag: msg_tag,
        data: msg_data

    # Handle errors
    rescue StandardError => e
      #puts "handle_receive: exception: #{e.inspect}"
      log_error "UNEXPECTED EXCEPTION: #{e.inspect}"
      raise MqConsumerException, e.message
    end

    def consumer_cancelled all={}
      log_error "consumer_cancelled remotely: #{all.inspect}"
    end

    def extract_delay msg_headers
      sent_at = msg_headers['sent_at'].to_s
      return if sent_at.empty?

      # Extract sent_at header
      sent_at = Time.parse(msg_headers['sent_at'])

      rescue StandardError => ex
        log_error "extract_delay: can't parse sent_at [#{sent_at}] (#{ex.message})"
        return nil

      else
        # Compute delay
        return ((Time.now - sent_at)*1000).round(2)
    end

    def handle_message context, metadata, delivery_info, message = {}
      log_error "MqConsumer.handle_message [#{context.to_s}] #{message.inspect}"
    end

    def payload_parse payload, content_type #, fields = []
      # Force encoding (pftop...)
      utf8payload = payload.to_s.force_encoding('UTF-8')

      # Parse payload if content-type provided
      case content_type
        when "application/json"
          return JSON.parse utf8payload rescue nil
        when "text/plain"
          return utf8payload.to_s
        else
          return utf8payload
      end

    # Handle body parse errors
    rescue Encoding::UndefinedConversionError => e
      log_error "parse: JSON PARSE ERROR: #{e.inspect}"
      return {}
    end

  end
end
