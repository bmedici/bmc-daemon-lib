module BmcDaemonLib
  class WorkerBase
    include LoggerHelper

    # Class options
    attr_reader :pool
    attr_reader :wid

    def initialize wid, pool = nil
      # Logger
      # FIXME log_pipe
      @logger = LoggerPool.instance.get :workers
      @log_worker_status_changes = true

      # Configuration
      @config = {}

      # Set thread context
      Thread.current.thread_variable_set :wid, (@wid = wid)
      Thread.current.thread_variable_set :pool, (@pool = pool)
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status WORKER_STATUS_STARTING

      # Ask worker to init itself, and return if there are errors
      if worker_init_result = worker_init
        log_error "worker_init aborting: #{worker_init_result.inspect}", @config
      else
        # We're ok, let's start out loop
        start_loop
      end
    end

  protected

    # Worker methods prototypes
    def worker_init
    end
    def worker_after
    end
    def worker_process
    end
    def worker_config
    end

    def start_loop
      log_info "start_loop starting", @config
      loop do
        begin
          # Do the hard work
          worker_process

          # Do the cleaning/sleeping stuff
          worker_after

        rescue StandardError => e
          log_error "WORKER EXCEPTION: #{e.inspect}"
          sleep 1
        end
      end
    end

    def worker_status status, job = nil
      # Update thread variables
      Thread.current.thread_variable_set :status, status
      Thread.current.thread_variable_set :updated_at, Time.now

      # Nothin' to log if "silent"
      return unless @log_worker_status_changes

      # Log this status change
      # if defined?'Job' && job.is_a?(Job)
      #   log_info "status [#{status}] on job[#{job.id}] status[#{job.status}] error[#{job.error}]"
      # else
      log_info "status [#{status}]"
      # end
    end

    def config_section key
      # Debugging
      @log_worker_status_changes = @debug

      # Set my configuration
      if (Conf[key].is_a? Hash) && Conf[key]
        @config = Conf[key]
      else
        log_error "missing [#{key}] configuration"
      end
    end

  end
end
