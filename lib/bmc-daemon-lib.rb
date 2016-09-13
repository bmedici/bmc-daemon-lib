# Global libs
require "rubygems"
require "syslog"
require "thread"
require "chamber"

# Project's libs
require_relative "bmc-daemon-lib/conf"
require_relative "bmc-daemon-lib/logger_formatter"
require_relative "bmc-daemon-lib/logger_helper"
require_relative "bmc-daemon-lib/logger_pool"
require_relative "bmc-daemon-lib/worker_base"
require_relative "bmc-daemon-lib/mq_endpoint"
require_relative "bmc-daemon-lib/mq_consumer"
