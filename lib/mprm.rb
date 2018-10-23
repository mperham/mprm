require 'logger'

module MPRM
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(STDOUT)
  self.logger.level = Logger::DEBUG
end

require 'mprm/version'
require 'mprm/repo'
