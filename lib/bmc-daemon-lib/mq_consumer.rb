require "bunny"

module BmcDaemonLib
  # class ShouterResponseError       < StandardError; end
  # class ShouterChannelClosed       < StandardError; end
  # class ShouterPreconditionFailed  < StandardError; end
  # class ShouterInterrupted         < StandardError; end
  # class EndpointTopicContext       < StandardError; end
  class EndpointConnexionContext    < StandardError; end
  class EndpointConnectionError     < StandardError; end
  class EndpointSubscribeContext    < StandardError; end
  class EndpointSubscribeError      < StandardError; end

  class MqConsumer
    include LoggerHelper
    attr_reader :logger

  protected

    def log_prefix
      self.class.name.split('::').last
    end

    def subscribe_on_queue name
      info "use_queue [#{name}]"

      # Queue for this rule
      @queue = @channel.queue(name, auto_delete: false, durable: true)

      # Create consumer on this queue
      @queue.subscribe(manual_ack: AMQP_MANUAL_ACK, on_cancellation: :consumer_cancelled) do |delivery_info, metadata, payload|
        # Prepare data
        msg_exchange = delivery_info.exchange
        msg_rkey = delivery_info.routing_key.force_encoding('UTF-8')
        msg_tag = delivery_info.delivery_tag

        msg_headers = metadata.headers || {}

        # Extract payload
        msg_data = payload_parse payload, metadata.content_type

        # Announce
        announce    msg_rkey, msg_tag, msg_data, metadata,      msg_exchange, payload.bytesize

        # Hand to the callback
        receive     msg_rkey, msg_tag, msg_data, metadata,      delivery_info
      end
    end

    def announce msg_rkey, msg_tag, msg_data, metadata, msg_exchange, payload_bytesize
      # Prepare data
      msg_headers = metadata.headers || {}

      # Announce match
      log_message MSG_RECV, msg_exchange, msg_rkey, msg_data, {
        'channel.dtag' => "#{@channel.id}.#{msg_tag}",
        'app-id' => metadata.app_id,
        'content-type' => metadata.content_type,
        'delay (ms)' => extract_delay(msg_headers),
        'body size' => format_bytes(payload_bytesize, "B"),
        }
    end

    def bind_on topic, route
      # Exchange to this rule
      exchange = @channel.topic(topic, durable: true, persistent: false)

      info "bind_on [#{topic}] [#{route}] > [#{@queue.name}]"
      @queue.bind exchange, routing_key: route
    end

    def consumer_cancelled all={}
      error "consumer cancelled remotely: #{all.inspect}"
    end

    def identifier len
      rand(36**len).to_s(36)
    end

    def log_message msg_way, msg_exchange, msg_key, msg_body = [], msg_attrs = {}
      # Message header
      info sprintf("%3s %-15s %s", msg_way, msg_exchange, msg_key)

      # Body lines
      if msg_body.is_a?(Enumerable) && !msg_body.empty?
        body_json = JSON.pretty_generate(msg_body)
        log_debug nil, body_json.lines
      end

      # Attributes lines
      log_debug nil, msg_attrs if msg_attrs
    end

    def extract_delay msg_headers
      return unless msg_headers['sent_at']

      # Extract sent_at header
      sent_at = Time.iso8601(msg_headers['sent_at']) rescue nil
      # log_info "sent_at     : #{sent_at.to_f}"
      # log_info "timenow     : #{Time.now.to_f}"

      # Compute delay
      return ((Time.now - sent_at)*1000).round(2)
    end

    def format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log(number) / Math.log(2) ).to_i / 10
      converted = number.to_f / (1024 ** index)

      truncated = converted.round(decimals)
      return "#{truncated} #{units[index]}#{unit}"
    end

    def receive delivery_info, metadata, payload
      debug "MqConsumer.receive"
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
