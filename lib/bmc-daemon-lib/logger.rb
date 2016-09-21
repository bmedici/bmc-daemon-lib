require "logger"
module BmcDaemonLib
  class Logger < Logger

    def initialize filename, rotation
      super

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
    end

  end
end
