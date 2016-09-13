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

  class MqEndpoint
    include LoggerHelper
    attr_reader :logger

  protected

    def log_prefix
      self.class.name.split('::').last
    end

    def log_message msg_way, msg_topic, msg_key, msg_body = [], msg_attrs = {}
      # Message header
      header = sprintf("%4s %-20s %s", msg_way, msg_topic, msg_key)
      log_debug header, msg_attrs if msg_attrs

      # Body lines
      if msg_body.is_a?(Enumerable) && !msg_body.empty?
        body_json = JSON.pretty_generate(msg_body)
        log_debug nil, body_json.lines
      end

    end

    def format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log(number) / Math.log(2) ).to_i / 10
      converted = number.to_f / (1024 ** index)

      truncated = converted.round(decimals)
      return "#{truncated} #{units[index]}#{unit}"
    end

    # Start connexion to RabbitMQ
    def connect_to busconf
      fail BmcDaemonLib::EndpointConnexionContext, "connect_to/busconf" unless busconf
      log_info "connecting to bus", {
        broker: busconf,
        recover: AMQP_RECOVERY_INTERVAL,
        heartbeat: AMQP_HEARTBEAT_INTERVAL,
        prefetch: AMQP_PREFETCH
        }
      conn = Bunny.new busconf.to_s,
        logger: @logger,
        # heartbeat: :server,
        automatically_recover: true,
        network_recovery_interval: AMQP_RECOVERY_INTERVAL,
        heartbeat_interval: AMQP_HEARTBEAT_INTERVAL,
        read_write_timeout: AMQP_HEARTBEAT_INTERVAL*2
      conn.start

    rescue Bunny::TCPConnectionFailedForAllHosts, Bunny::AuthenticationFailureError, AMQ::Protocol::EmptyResponseError  => e
      fail BmcDaemonLib::EndpointConnectionError, "error connecting (#{e.class})"
    rescue StandardError => e
      fail BmcDaemonLib::EndpointConnectionError, "unknow (#{e.inspect})"
    else
      return conn
    end

  end
end
