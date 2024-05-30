# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

require "logger"

require_relative "failure"
require_relative "result"

module SorbetOperation
  # Abstract base class for operations.
  #
  # Subclasses must:
  #
  # 1. define the {ValueType} type member
  # 2. implement the {#execute} method
  class Base
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    abstract!

    # The type of the value returned by this operation. The type can be any
    # valid Sorbet type, as long as it's a subtype of `Object`.
    #
    # @example If the operation returns a String or nil
    #   ValueType = type_member { { fixed: T.nilable(String) } }
    #
    # @example If the operation does not return a value
    #   ValueType = type_member { { fixed: NilClass } }
    #
    # @see https://sorbet.org/docs/generics#type_member--type_template
    # @see https://sorbet.org/docs/generics#bounds-on-type_members-and-type_templates-fixed-upper-lower
    ValueType = type_member { { upper: Object } }

    # Performs the operation and returns the result.
    sig { returns(Result[ValueType]) }
    def perform
      logger.debug("Performing operation #{self.class.name}")

      begin
        value = execute
      rescue Failure => e
        logger.debug("Operation #{self.class.name} failed, failure = #{e.inspect}")

        Result.new(false, nil, e)
      else
        logger.debug("Operation #{self.class.name} succeeded, return value = #{value.inspect}")

        Result.new(true, value, nil)
      end
    end

    # The logger for this operation.
    sig { params(logger: ::Logger).void }
    attr_writer :logger

    private

    # Implement this method in subclasses to perform the operation.
    #
    # This method must either return a value of type {ValueType}, in which
    # case the operation is considered successful, or raise an exception of
    # type {SorbetOperation::Failure}, in which case the operation is
    # considered failed.
    #
    # Raising an exception of any other type will result in an unhandled
    # exception. The exception will not be caught and will be propagated to
    # the caller.
    #
    # This method should be declared as `private` in subclasses to prevent
    # callers from calling it directly. Callers should instead call {#perform}
    # to perform the operation and get the result.
    sig { abstract.returns(ValueType) }
    def execute; end

    # Returns the logger for this operation. If no logger has been set, the
    # default logger will be returned instead.
    sig { returns(::Logger) }
    def logger
      @logger ||= T.let(SorbetOperation.default_logger, T.nilable(::Logger))
    end
  end
end
