require "logger"

module BmcDaemonLib
  module LoggerHelper
    # Use accessor to expose logger to Grape, who uses .logger
    attr_accessor :logger

  protected

    def log_pipe pipe, caller = nil
      @log_pipe = pipe
      @logger = BmcDaemonLib::LoggerPool.instance.get pipe
      @caller = caller
      #Conf.log "log #{@log_pipe}", "log_to pipe: #{pipe} logger class: #{@logger.class}"
      #return @logger
    end

    def log_context
      {}      # ['DEFAULT', self.class.name.split('::').last]
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
      # puts "LoggerHelper.log > #{message}"
      # puts "LoggerHelper.log     > #{get_full_context.inspect}"
      logger.add severity, message, get_full_context, details
    end

    def get_full_context
      # Grab the classe's context
      context = log_context()

      # Initialize an empty context, if log_context returned something else, or it the method was not exposed
      context = {} unless context.is_a? Hash

      # Who is the caller? Guess it from caller's class name if not provided
      context[:caller] ||= get_class_name

      # Return the whole context
      return context
    end

    # alias info log_info
    # alias error log_error
    # alias debug log_debug
    def get_class_name
      self.class.name.to_s.split('::').last
    end

  end
end
