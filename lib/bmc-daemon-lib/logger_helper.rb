require "logger"

module BmcDaemonLib
  module LoggerHelper

  protected

    def log_info message, details = nil
      log Logger::INFO, message, details
    end

    def log_error message, details = nil
      log Logger::ERROR, message, details
    end

    def log_debug message, details = nil
      log Logger::DEBUG, message, details
    end

    alias info log_info
    alias error log_error
    alias debug log_debug

    def log severity, message, details = nil
      fail "LoggerHelper.log: invalid logger" unless logger.respond_to? :add

      messages = []

      prefix = build_prefix

      # Add main message
      messages << sprintf(LOG_MESSAGE_TEXT, prefix, message) if message

      # Add details from array
      details.each do |line|
        messages << sprintf(LOG_MESSAGE_ARRAY, prefix, line)
      end if details.is_a? Array

      # Add details from hash
      details.each do |key, value|
        messages << sprintf(LOG_MESSAGE_HASH, prefix, key, value)
      end if details.is_a? Hash

      # Return all that stuff
      logger.add severity, messages
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

  end
end
