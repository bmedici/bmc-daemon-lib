# Global libs
require "rubygems"
require "syslog"
require "thread"
require "newrelic_rpm"


# Project's libs
require_relative "bmc-daemon-lib/conf"
require_relative "bmc-daemon-lib/logger_formatter"
require_relative "bmc-daemon-lib/logger_helper"
require_relative "bmc-daemon-lib/logger_pool"
require_relative "bmc-daemon-lib/worker_base"
