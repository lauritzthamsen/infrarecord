require "infrarecord/version"

module Infrarecord
  mattr_accessor :app_root

  # Yield self on setup for nice config blocks
  def self.setup
    yield self
  end

  # Require our engine
  require "infrarecord/engine"
end
