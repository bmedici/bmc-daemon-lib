require "logger"
require "singleton"

# Logger interface class to access logger though symbolic names
module BmcDaemonLib
  class LoggerPool
    include Singleton
    LOG_ROTATION            = "daily"

    def get pipe = nil
      # If not provided, use :default
      pipe = :default if pipe.to_s.empty?

      # Instantiate a logger or return the existing one
      @loggers ||= {}
      @loggers[pipe] ||= create(pipe)
    end

    def create pipe
      # Compute logfile or STDERR, and declare what we're doing
      filename = Conf.logfile(pipe)

      # Create the logger and return it
      logger = Logger.new(filename, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.downcase
      logger.formatter = LoggerFormatter

      # Finally return this logger
      logger

    rescue Errno::EACCES
      $stderr.puts "LoggerPool: create [#{pipe}]: access error"
    end

  end
end
