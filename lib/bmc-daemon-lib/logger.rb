require "logger"
module BmcDaemonLib
  class Logger < Logger

    DEFAULT_FORMAT = {
      # header: "%s ‡ %d\t%-8s %-12s ",
      header: "%{time} %7{pid} %-6{severity} %-10{pipe} | %{context}",
      # header: "%{time} %7{pid} %-6{severity} %-10{pipe}(-‡-)%{context}",
      time:   "%Y-%m-%d %H:%M:%S",
      context: "[%s]",
      text:   "%s",
      array:  "     ·%s",
      hash:   "     ·%-15s %s",
      trim:   400,
      }

    def initialize filename, rotation
      # Initialize
      super
      @format = DEFAULT_FORMAT

      # Import LOGGER_FORMAT if defined
      if (defined?'LOGGER_FORMAT') && (LOGGER_FORMAT.is_a? Hash)
        @format.merge! LOGGER_FORMAT
      end

      # Define formatter
      self.formatter = proc do |severity, datetime, progname, messages|
        formatter(severity, datetime, progname, messages)
      end
    end

  protected

    def trimmed line
      line.to_s.rstrip[0..@format[:trim].to_i].force_encoding(Encoding::UTF_8)
    end

    def formatter severity, datetime, context, messages
      # Build header with time and context
      header = @format[:header] % {
        time: datetime.strftime(@format[:time]),
        pid: Process.pid,
        severity: severity,
        pipe: self.progname,
        context: build_context(context)
        }

      # If we have a plain message, we're done
      return "#{header} #{trimmed(payload)}\n" unless messages.is_a?(Array)

      # If we have a bunch of lines, prefix them and send them together
      return messages.collect do |line|
        "#{header} #{trimmed(line)}\n"
      end.join
    end

  private

    # Builds prefix from @format[:context] and values
    def build_context values
      # Skip if no format defined
      return "[context is not a hash]" unless @format[:context].is_a? Hash

      # Call the instance's method to get hash values
      return "[log_context is not a hash]" unless values.is_a? Hash

      # Build each context part
      return @format[:context].collect do |key, format|
        sprintf(format, values[key])
      end.join

    rescue KeyError, ArgumentError => ex
      return "[context: #{ex.message}]"
    end

  end
end
