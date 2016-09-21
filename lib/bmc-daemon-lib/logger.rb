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

    def initialize filename, rotation = nil
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

    def add severity, message, context = nil, details = nil
      # Start from an empty messages list with the main message
      messages = []
      messages << sprintf(@format[:text], message) if message

      # Add details from array
      details.each do |line|
        messages << sprintf(@format[:array], line)
      end if details.is_a? Array

      # Add details from hash
      details.each do |key, value|
        messages << sprintf(@format[:hash], key, value)
      end if details.is_a? Hash

      # Pass all that stuff to my parent
      super severity, messages, context
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

    # Builds prefix from @format[:context] and context
    def build_context context
      # Skip if no format defined
      return unless @format[:context].is_a? Hash

      # Call the instance's method to get hash context
      return unless context.is_a? Hash

      # Build each context part
      return @format[:context].collect do |key, format|
        sprintf(format, context[key])
      end.join

    rescue KeyError, ArgumentError => ex
      return "[context: #{ex.message}]"
    end

  end
end
