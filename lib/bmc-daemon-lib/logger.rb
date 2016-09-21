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

    def formatter severity, datetime, context, messages
    end

  end
end
