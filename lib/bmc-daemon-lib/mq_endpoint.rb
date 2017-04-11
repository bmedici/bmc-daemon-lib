module BmcDaemonLib
  class EndpointConnexionContext    < StandardError; end
  class EndpointConnectionError     < StandardError; end
  class EndpointSubscribeContext    < StandardError; end
  class EndpointSubscribeError      < StandardError; end

  class MqEndpoint
    include LoggerHelper
    attr_accessor :logger

    def initialize channel, *args
      # Init
      @channel = channel
      log_info "MqEndpoint on channel [#{@channel.id}]"
    end

  protected

    def log_message msg_way, msg_topic, msg_key, msg_body = [], msg_attrs = {}
      # Message header
      log_info sprintf("%4s %-20s %s", msg_way, msg_topic, msg_key)

      # Message attributes
      log_debug nil, msg_attrs if msg_attrs

      # Body lines
      if msg_body.is_a?(Enumerable) && !msg_body.empty?
        body_json = JSON.pretty_generate(msg_body)
        log_debug nil, body_json.lines
      end
    end

    def identifier len
      rand(36**len).to_s(36)
    end

    def format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log(number) / Math.log(2) ).to_i / 10
      converted = number.to_f / (1024 ** index)

      truncated = converted.round(decimals)
      return "#{truncated} #{units[index]}#{unit}"
    end

  end
end
