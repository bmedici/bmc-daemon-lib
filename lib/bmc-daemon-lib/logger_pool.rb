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
      puts "logging [#{pipe}] failed: access error"
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
          puts "logging [#{pipe}] disabled: file not writable [#{logfile}]"
          return nil
        end
      else
        # No file here, can we create it ?
        logdir = File.dirname(logfile)
        unless File.writable?(logdir)
          puts "logging [#{pipe}] disabled: directory not writable [#{logdir}]"
          return nil
        end
      end

      # OK, return a clean file path
      puts "logging [#{pipe}] to [#{logfile}]"
      return logfile
    end

  end
end
