require "logger"

module BmcDaemonLib
  module LoggerHelper

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
      context = log_context
      return unless context.is_a? Hash
      end

      # Change to an array if a simple string
      values = [values] if values.is_a? String

      # Ensure we always have an array (method not found, or log_prefix returning something else)
      values = [] unless values.is_a? Array

      # Finally format the string
      return LOG_PREFIX_FORMAT % values.map(&:to_s)

    end

    # alias info log_info
    # alias error log_error
    # alias debug log_debug

  end
end
