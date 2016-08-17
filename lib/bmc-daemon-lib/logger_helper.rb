require "logger"

module BmcDaemonLib
  module LoggerHelper

  protected

    def log_info message, details = nil
      build_messages Logger::INFO, message, details
    end

    def log_error message, details = nil
      build_messages Logger::ERROR, message, details
    end

    def log_debug message, details = nil
      build_messages Logger::DEBUG, message, details
    end

    alias info log_info
    alias error log_error
    alias debug log_debug

  private

    # Builds prefix if LOG_PREFIX_FORMAT defined and caller has log_prefix method to provide values
    def build_prefix
      # Skip if no format defined
      return unless defined?('LOG_PREFIX_FORMAT')
      return unless LOG_PREFIX_FORMAT.is_a? String

      # Skip if no values from user class
      return unless respond_to?(:log_prefix, true)
      values = log_prefix

      # Change to an array if not already
      values = [values] if values.is_a? String

      # Stop if still not an array
      return unless values.is_a? Array

      # Finally format the string
      return LOG_PREFIX_FORMAT % values.map(&:to_s)

    rescue ArgumentError
      return "INVALID_FORMAT"
    end

    def build_messages severity, message, details = nil
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

  end
end
