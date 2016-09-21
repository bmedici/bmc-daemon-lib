require "logger"

module BmcDaemonLib
  module LoggerHelper
    # Use accessor to expose logger to Grape, as it uses logger.*
    attr_accessor :logger

  protected

    def log_pipe pipe, caller = nil
      @log_pipe = pipe
      @logger = BmcDaemonLib::LoggerPool.instance.get(pipe)
      @caller = caller
    end

    def log_context
      {}
    end

    def log_info message, details = nil
      log Logger::INFO, message, details
    end
    def log_error message, details = nil
      log Logger::ERROR, message, details
    end
    def log_debug message, details = nil
      log Logger::DEBUG, message, details
    end

  private

    def log severity, message, details
      return puts "LoggerHelper.log: missing logger (#{get_class_name})" unless logger
      logger.add severity, message, full_context, details
    end

    def full_context
      # Grab the classe's context
      context = log_context()

      # Initialize an empty context, (log_context returned something bad, or method was not exposed)
      context = {} unless context.is_a? Hash

      # Who is the caller? Guess it from caller's class name if not provided
      context[:caller] ||= get_class_name

      # Return the whole context
      return context
    end

    def get_class_name
      self.class.name.to_s.split('::').last
    end

  end
end
