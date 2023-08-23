# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

require "logger"

# foo
#
# fewfwefw
module SorbetOperation
  class << self
    extend T::Sig

    # Returns the default logger used by operations.
    sig { returns(::Logger) }
    def default_logger
      @default_logger ||= T.let(::Logger.new($stdout, level: ::Logger::INFO), T.nilable(::Logger))
    end

    # Sets the default logger used by operations.
    sig { params(default_logger: T.nilable(::Logger)).void }
    attr_writer :default_logger
  end
end

require_relative "sorbet_operation/base"
require_relative "sorbet_operation/failure"
require_relative "sorbet_operation/result"
require_relative "sorbet_operation/version"
