# FIXME: files named with hyphens will not be found by Chamber for now
module BmcDaemonLib
  # Class exceptions
  class ConfigInitiRequired       < StandardError; end
  class ConfigMissingParameter    < StandardError; end
  class ConfigOtherError          < StandardError; end
  class ConfigParseError          < StandardError; end

  class ConfigGemspecNotUnique    < StandardError; end
  class ConfigGemspecMissing      < StandardError; end
  class ConfigGemspecInvalid      < StandardError; end

  class Conf
    extend Chamber
    PIDFILE_DIR = "/tmp/"

    # Set up encodings
    Encoding.default_internal = "utf-8"
    Encoding.default_external = "utf-8"

    # Some global init
    @app_started  = Time.now
    @app_name     = "[app_name]"
    @app_env      = "production"
    @app_host     =  `hostname`.to_s.chomp.split(".").first
    class << self
      attr_reader   :app_root
      attr_reader   :app_started
      attr_reader   :app_name
      attr_reader   :app_env
      attr_reader   :app_host
      attr_reader   :app_libs
      attr_reader   :app_ver
      attr_reader   :app_spec
      attr_reader   :files
      attr_reader   :config_defaults
      attr_reader   :config_etc

      config_defaults
    end


      # Default values
      @files        ||= []
      attr_reader   :app_config

      # By default, Newrelic is disabled
      ENV["NEWRELIC_AGENT_ENABLED"] = "false"

      # Store and clean app_root, don't do anything more if not provided
      return unless app_root
      @app_root = File.expand_path(app_root)
      init_from_gemspec app_root
      def app_env= value
        @app_env = value
        ENV["RACK_ENV"] = value.to_s
      end

      # Now we know app_name, initalize app_libs
      @app_libs = File.expand_path("lib/#{@app_name}/", @app_root)
      def app_config= path
        @app_config= path
      end

      # Add other config files
      @config_defaults = "#{@app_root}/defaults.yml"
      @config_etc = "/etc/#{@app_name}.yml"
      def cmd_config= path
        @app_config= path
      end


      add_config @config_defaults
      add_config @config_etc
    end



    def self.prepare args = {}
      ensure_init

      # Add extra config file and load them all
      add_config args[:config]

      # Set up encodings
      Encoding.default_internal = "utf-8"
      Encoding.default_external = "utf-8"

    rescue Psych::SyntaxError => e
      fail ConfigParseError, e.message
    rescue StandardError => e
      fail ConfigOtherError, "#{e.message} \n #{e.backtrace.to_yaml}"
    end

    def self.dump
      ensure_init
      to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
    end

    # Direct access to any depth
    def self.at *path
      ensure_init
      path.reduce(Conf) { |m, key| m && m[key.to_s] }
    end

    def self.logfile pipe
      # Build logfile from Conf
      logfile = self.logfile_path(pipe)
      return nil if logfile.nil?

      # Check that we'll be able to create logfiles
      if File.exists?(logfile)
        # File is there, is it writable ?
        unless File.writable?(logfile)
          log :conf, "logging [#{pipe}] disabled: file not writable [#{logfile}]"
          return nil
        end
      else
        # No file here, can we create it ?
        logdir = File.dirname(logfile)
        unless File.writable?(logdir)
          log :conf, "logging [#{pipe}] disabled: directory not writable [#{logdir}]"
          return nil
        end
      end

      # OK, return a clean file path
      log :conf, "logging [#{pipe}] to [#{logfile}]"
      return logfile
    end

    # Feature testers
    def self.gem_installed? gemname
      Gem::Specification.collect(&:name).include? gemname
    end


    def self.feature_newrelic?
      ensure_init
      return false unless gem_installed?('newrelic_rpm')
      return false if self.at(:newrelic, :enabled) == false
      return false if self.at(:newrelic, :disabled) == true
      return self.at(:newrelic, :license) || false
    end
    def self.feature_rollbar?
      ensure_init
      return false unless gem_installed?('rollbar')
      return false if self.at(:rollbar, :enabled) == false
      return false if self.at(:rollbar, :disabled) == true
      return self.at(:rollbar, :token) || false
    end

    def self.feature? name
      case name
      when :newrelic
        return feature_newrelic?
      when :rollbar
        return feature_rollbar?
      end
      return false
    end

    # Generators
    def self.generate_user_agent
      ensure_init
      "#{@app_name}/#{@app_ver}" if @app_name && @app_ver
    end
    def self.generate_process_name
      ensure_init
      parts = [@app_name, @app_env]
      parts << self[:port] if self[:port]
      parts.join('-')
    end
    def self.generate_pidfile
      ensure_init
      File.expand_path "#{self.generate_process_name}.pid", PIDFILE_DIR
    end
    def self.generate_config_message
      return unless @config_defaults && @config_etc
      "A default configuration is available (#{@config_defaults}) and can be copied to the default location (#{@config_etc}): \n sudo cp #{@config_defaults} #{@config_etc}"
    end

    def self.prepare_newrelic
      # Disable if no config present
      return unless self.feature?(:newrelic)

      # Ok, let's start
      log :conf, "prepare NewRelic"
      conf = self[:newrelic]

      # Enable GC profiler
      GC::Profiler.enable

      # Build NewRelic app_name if not provided as-is
      self.newrelic_init_app_name(conf)

      # Set env variables
      ENV["NEW_RELIC_AGENT_ENABLED"] = "true"
      ENV["NEW_RELIC_LOG"] = logfile_path(:newrelic)
      ENV["NEW_RELIC_LICENSE_KEY"] = conf[:license].to_s
      ENV["NEW_RELIC_APP_NAME"] = conf[:app_name].to_s

      # logger_newrelic = Logger.new('/tmp/newrelic.log')
      # logger_newrelic.debug Time.now()
      # Start the agent
      # NewRelic::Agent.manual_start({
      #   agent_enabled: true,
      #   log: logger_newrelic,
      #   env: @app_env,
      #   license_key: conf[:license].to_s,
      #   app_name: conf[:app_name].to_s,
      # })
    end

    def self.prepare_rollbar
      # Disable if no config present
      unless self.feature?(:rollbar)
        Rollbar.configure do |config|
          config.enabled = false
        end
        return
      end

      # Ok, let's start
      log :conf, "prepare Rollbar"
      conf = self[:rollbar]

      # Configure
      Rollbar.configure do |config|
        config.enabled = true
        config.access_token = conf[:token].to_s
        config.code_version = @app_version
        config.environment  = @app_env
        config.logger       = LoggerPool.instance.get(:rollbar)
        config.use_async = true
      end

      # Notify startup
      Rollbar.info("[#{@app_ver}] #{@host}")
    end

    def self.log origin, message
      printf(
        "%s %-14s %s \n",
        Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        origin,
        message
        )
    end

  protected

    def self.init_from_gemspec
      gemspec_path = "#{@app_root}/*.gemspec"

      # Try to find any gemspec file
      matches   = Dir[gemspec_path]
      fail ConfigGemspecMissing, "gemspec file not found: #{gemspec_path}" if matches.size < 1
      fail ConfigGemspecNotUnique, "gemspec file not found: #{gemspec_path}" if matches.size > 1

      # Load Gemspec (just the only match)
      @spec     = Gem::Specification::load(matches.first)
      fail ConfigGemspecInvalid, "gemspec not readable: #{gemspec_path}" unless @spec

      # Extract useful information from gemspec
      @app_name = @spec.name.to_s
      @app_ver  = @spec.version.to_s
      fail ConfigMissingParameter, "gemspec: missing name" unless @app_name
      fail ConfigMissingParameter, "gemspec: missing version" unless @app_ver
    end

    def self.newrelic_init_app_name conf
      # Ignore if already set
      return if conf[:app_name]

      # Stack all those parts
      stack = []
      stack << (conf[:prefix] || @app_name)
      stack << conf[:platform] if conf[:platform]
      stack << @app_env
      text = stack.join('-')

      # Return a composite appname
      conf[:app_name] = "#{text}; #{text}-#{@host}"
    end

    def self.add_config path
      # Skip if path is not readable
      return unless path && File.readable?(path)

      # Check if Chamber's behaviour may cause problems with hyphens
      basename = File.basename(path)
      if File.basename(path).include?'-'
        log :conf, "WARNING: files with dashes may cause unexpected behaviour with Chamber (#{basename})"
      end

      # Store the files
      @files << File.expand_path(path) 

      # Reload config
      load files: @files, namespaces: { environment: @app_env }

      # Try to access any key to force parsing of the files
      self[:test35547647654856865436346453754746588586799078079876543245678654324567865432]
    end

    def self.logfile_path pipe
      # Access configuration
      path      = self.at :logs, :path
      specific  = self.at :logs, pipe
      default   = self.at :logs, :default

      # Ignore if explicitely disabled
      return nil if specific == false

      # Fallback on default path if not provided,
      specific ||= default
      specific ||= "default.log"

      # Build logfile_path
      File.expand_path specific.to_s, path.to_s
    end

  private

    def self.ensure_init
      unless @initialized
        fail ConfigInitiRequired, "ensure_init: Conf.init(app_root) should be invoked beforehand"
      end
    end

  end
end
