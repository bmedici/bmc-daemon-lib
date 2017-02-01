module BmcDaemonLib
  class Worker
    include LoggerHelper

    # Statuses
    STATUS_STARTING  = "starting"
    STATUS_READY     = "ready"
    STATUS_WORKING   = "working"
    STATUS_SLEEPING  = "sleeping"
    STATUS_FINISHED  = "finished"
    STATUS_CRASHED   = "crashed"
    STATUS_TIMEOUT   = "timeout"

    # Class options
    attr_reader :pool
    attr_reader :wid

    def initialize wid, pool = nil
      # Logger
      log_pipe :workers
      @log_worker_status_changes = true

      # Configuration
      @config = {}

      # Set thread context
      Thread.current.thread_variable_set :wid, (@wid = wid)
      Thread.current.thread_variable_set :pool, (@pool = pool)
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status STATUS_STARTING

      # Ask worker to init itself, and return if there are errors
      if worker_init_result = worker_init
        log_warn "aborting: #{worker_init_result.inspect}", @config
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

    def worker_sleep seconds
      return if seconds.nil? || seconds.to_f == 0.0
      worker_status STATUS_SLEEPING
      log_info "worker_sleep: #{seconds}", @config
      sleep seconds
    end

    def working_on_job(job, working_on_it = false)
      if working_on_it
        job.wid = Thread.current.thread_variable_get :wid
        Thread.current.thread_variable_set :jid, job.id
      else
        job.wid = nil
        Thread.current.thread_variable_set :jid, nil
      end
    end

    def start_loop
      log_info "start_loop starting", @config
      loop do
        begin
          # Announce we're waiting for work
          worker_status STATUS_READY

          # Do the hard work
          worker_process

          # Should we sleep ?
          worker_sleep @config[:timer]

        rescue StandardError => e
          log_error "WORKER EXCEPTION: #{e.inspect}"
          sleep 1
        end
      end
    end

    def worker_status status
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
