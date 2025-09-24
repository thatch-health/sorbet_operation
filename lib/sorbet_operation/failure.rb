# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module SorbetOperation
  # Exception class used to indicate that an operation failed.
  #
  # Raise this exception (or a subclass of it) from an operation's
  # {SorbetOperation::Base#execute} method to indicate that the operation
  # failed.
  #
  # If you need to pass additional information about the failure, you can
  # subclass this exception and add any additional attributes you need.
  class Failure < ::StandardError
  end
end
