# Global libs
require "rubygems"
require "thread"
require "chamber"
require "time"

# Project's libs
require_relative "bmc-daemon-lib/conf"

require_relative "bmc-daemon-lib/logger"
require_relative "bmc-daemon-lib/logger_helper"
require_relative "bmc-daemon-lib/logger_pool"

require_relative "bmc-daemon-lib/worker"

require_relative "bmc-daemon-lib/mq_endpoint"
require_relative "bmc-daemon-lib/mq_consumer"
