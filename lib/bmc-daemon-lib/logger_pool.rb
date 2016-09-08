require "logger"
require "singleton"

# Logger interface class to access logger though symbolic names
module BmcDaemonLib
  class LoggerPool
    include Singleton

    LOG_ROTATION            = "daily"

    def get pipe = nil
      pipe = :default if pipe.to_s.empty?

      @loggers ||= {}
      @loggers[pipe] ||= create(pipe)
    end

    def create pipe
      # Compute logfile or STDERR, and declare what we're doing
      filename = logfile(pipe)

      # Create the logger and return it
      logger = Logger.new(filename, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.downcase
      logger.formatter = LoggerFormatter

      # Finally return this logger
      logger

    rescue Errno::EACCES
      log "create [#{pipe}]: access error"
    end

  protected

    def logfile pipe
      # Disabled if no valid config
      #return nil unless Conf[:logs].is_a?(Hash) && Conf.at(:logs, pipe)

      # Build logfile from Conf
      logfile = Conf.logfile_path pipe
      return nil if logfile.nil?

      # Check that we'll be able to create logfiles
      if File.exists?(logfile)
        # File is there, is it writable ?
        unless File.writable?(logfile)
          log "logging [#{pipe}] to [#{logfile}] disabled: file not writable [#{logfile}]"
          return nil
        end
      else
        # No file here, can we create it ?
        logdir = File.dirname(logfile)
        unless File.writable?(logdir)
          log "logging [#{pipe}] [#{logfile}] disabled: directory not writable [#{logdir}]"
          return nil
        end
      end

      # OK, return a clean file path
      log "logging [#{pipe}] to [#{logfile}]"
      return logfile
    end

    def log message
      Conf.log :logger, message
    end

  end
end
