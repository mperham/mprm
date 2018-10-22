require 'logger'

module PRM
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(STDOUT)
  self.logger.level = Logger::DEBUG
end

require 'prm/version'
require 'prm/repo'
