module BmcDaemonLib
  class LoggerFormatter

    def self.call severity, datetime, progname, payload
      # Build common values
      timestamp = datetime.strftime(LOG_HEADER_TIME)

      # Build header
      header = sprintf LOG_HEADER_FORMAT,
        timestamp,
        Process.pid,
        severity,
        progname

      # If we have a bunch of lines, prefix them and send them together
      return payload.map do |line|
        "#{header}#{trimmed(line)}\n"
      end.join if payload.is_a?(Array)

      # Otherwise, just prefix the only line
      return "#{header}#{trimmed(payload)}\n"
    end

  protected

  end
end
