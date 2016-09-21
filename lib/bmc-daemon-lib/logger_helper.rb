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

    # Builds prefix if LOG_PREFIX_FORMAT defined and caller has log_prefix method to provide values
    def build_prefix
      # Skip if no format defined
      return unless defined?('LOG_PREFIX_FORMAT')
      return unless LOG_PREFIX_FORMAT.is_a? String

      # At start, values is an empty array
      values = nil

      # Call the instance's method
      if respond_to?(:log_prefix, true)
        values = log_prefix
      end

      # Change to an array if a simple string
      values = [values] if values.is_a? String

      # Ensure we always have an array (method not found, or log_prefix returning something else)
      values = [] unless values.is_a? Array

      # Finally format the string
      return LOG_PREFIX_FORMAT % values.map(&:to_s)

    rescue ArgumentError => ex
      return "(LOG_PREFIX_FORMAT has an invalid format)"
    end

    # alias info log_info
    # alias error log_error
    # alias debug log_debug

  end
end
