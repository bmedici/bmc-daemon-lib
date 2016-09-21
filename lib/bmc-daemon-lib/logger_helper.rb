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
      logger.add Logger::INFO, message, get_full_context, details
    end
    def log_error message, details = nil
      logger.add Logger::ERROR, message, get_full_context, details
    end
    def log_debug message, details = nil
      logger.add Logger::DEBUG, message, get_full_context, details
    end

  private

    def get_full_context
      context = nil

      # Grab the classe's context
      context = log_context() if self.respond_to?(:log_context)

      # Initialize an empty context, if log_context returned something else, or it the method was not exposed
      context = {} unless context.is_a? Hash

      # Who is the caller? Guess it from caller's class name if not provided
      context[:caller] ||= self.class.name.to_s.split('::').last

      # Return the whole context
      return context
    end

    # alias info log_info
    # alias error log_error
    # alias debug log_debug

  end
end
