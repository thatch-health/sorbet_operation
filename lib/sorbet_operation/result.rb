# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

require_relative "failure"

module SorbetOperation
  # {SorbetOperation::Result} is a generic class that represents the result of
  # an operation, either success or failure.
  #
  # If the result is a success, it wraps a value of type member
  # {SorbetOperation::Result::ValueType}.
  #
  # If the result is a failure, it wraps an exception of type
  # {SorbetOperation::Failure}.
  class Result
    extend T::Sig
    extend T::Generic

    # The type of the value wrapped by the {Result}. The type can be any
    # valid Sorbet type, as long as it's a subtype of `Object`.
    ValueType = type_member { { upper: Object } }

    # Constructs a new {Result}, either a success or a failure.
    #
    # If `success` is `true`, then `value` must be provided (although it can
    # be nil, because {ValueType} may be nilable) and `error` must be nil.
    #
    # If `success` is `false`, then `value` must be nil and `error` must be
    # non-nil.
    #
    # Calling this constructor directly should rarely be necessary. In normal
    # usage, {SorbetOperation::Base#perform} will return a {Result} for you.
    sig { params(success: T::Boolean, value: T.nilable(ValueType), error: T.nilable(Failure)).void }
    def initialize(success, value, error)
      @success = success
      @value = value
      @error = error

      # NOTE: these checks are annoying. A better API would be to make this
      # constructor private and provide two factory methods:
      # - `Result.success(value)`
      # - `Result.failure(error)`
      #
      # However, in order to do this, we would need to be able to use
      # {ValueType} in class methods. At this time, there is no way to tell
      # Sorbet that a generic type applies to both the class and its
      # singleton. We would need to duplicate the value type:
      # ```
      # ValueTypeMember = type_member { { upper: Object } }
      # ValueTypeTemplate = type_template { { upper: Object } }
      # ```
      # and every subclass would need to specify both (and ensure that
      # they're both set to the same type). This would be quite clumsy. Since
      # `Result` should rarely be instantiated directly (rather, it's
      # instantiated by `SorbetOperation::Base#perform`), we'll just live with
      # this less than ideal API for now.
      if @success
        # We can't test that value is not nil because the value type can be
        # nilable. (In theory we could check if the type is nilable and only
        # apply the check if it's not, but that's not worth the complexity.)
        unless error.nil?
          raise ArgumentError, "Cannot pass an error to a success result"
        end
      elsif error.nil?
        raise ArgumentError, "Must pass an error to a failure result"
      elsif !value.nil?
        raise ArgumentError, "Cannot pass a value to a failure result"
      end
    end

    # Returns `true` if the result is a success.
    sig { returns(T::Boolean) }
    def success?
      @success
    end

    # Returns `true` if the result is a failure.
    sig { returns(T::Boolean) }
    def failure?
      !success?
    end

    # Returns the contained value if the result is a success, otherwise raises
    # the contained error.
    sig { returns(ValueType) }
    def unwrap!
      raise T.must(@error) if failure?

      casted_value
    end

    # Returns the contained value if the result is a success, otherwise
    # returns `nil`.
    sig { returns(T.nilable(ValueType)) }
    def safe_unwrap
      return if failure?

      casted_value
    end

    # Returns the contained value if the result is a success, otherwise
    # returns the provided default value.
    #
    # @example
    #   result = SomeOperation.new.perform
    #   result.failure? # => true
    #   value = result.unwrap_or(456)
    #   value # => 456
    sig { params(default: ValueType).returns(ValueType) }
    def unwrap_or(default)
      return casted_value if success?

      default
    end

    # Returns the contained value if the result is a success, otherwise calls
    # the block with the contained error and returns the block's return value.
    #
    # @example
    #   result = SomeOperation.new.perform
    #   result.failure? # => true
    #   value = result.unwrap_or_else { |_| 456 }
    #   value # => 456
    sig { params(blk: T.proc.params(error: Failure).returns(ValueType)).returns(ValueType) }
    def unwrap_or_else(&blk)
      return casted_value if success?

      yield(T.must(@error))
    end

    # Returns the contained error if the result is a failure, otherwise raises
    # an error.
    sig { returns(Failure) }
    def unwrap_error!
      return T.must(@error) if failure?

      # TODO: custom error type?
      raise "Called `unwrap_err!` on a success"
    end

    # Returns the contained error if the result is a failure, otherwise
    # returns `nil`.
    sig { returns(T.nilable(Failure)) }
    def safe_unwrap_error
      return T.must(@error) if failure?

      nil
    end

    # Yields the contained value if the result is a success, otherwise does
    # nothing. Returns `self` so this call can be chained to `#on_failure`.
    #
    # @example
    #   SomeOperation.new.perform
    #    .on_success { |value| puts "Success! Value: #{value}" }
    #    .on_failure { |error| puts "Failure! Error: #{error}" }
    sig { params(blk: T.proc.params(value: ValueType).void).returns(T.self_type) }
    def on_success(&blk)
      yield(casted_value) if success?
      self
    end

    # Yields the contained error if the result is a failure, otherwise does
    # nothing. Returns `self` so this call can be chained to `#on_success`.
    #
    # @example
    #   SomeOperation.new.perform
    #    .on_success { |value| puts "Success! Value: #{value}" }
    #    .on_failure { |error| puts "Failure! Error: #{error}" }
    sig { params(blk: T.proc.params(error: Failure).void).returns(T.self_type) }
    def on_failure(&blk)
      yield(T.must(@error)) if failure?
      self
    end

    private

    # A word of explanation as to why this is necessary: the `value` argument
    # in `Result`'s constructor is typed as `T.nilable(ValueType)`, because it
    # will be `nil` for failure results.
    #
    # The signatures for `unwrap!`, `unwrap_or_else`, and `on_success` all use
    # (non-nilable) `ValueType` because in those cases, we know that the result
    # is a success.
    #
    # However, `ValueType` can be nilable, in which case `nil` is a valid
    # value for a success result. As a result, we can't just wrap `value` in
    # `T.must`. Instead, we cast `@value` from `T.nilable(ValueType)` to
    # `ValueType`, which is ~the same thing as `T.must` but doesn't raise a
    # runtime error if `ValueType` is nilable and `@value` is `nil`.
    #
    # There's probably a better way to handle this.
    sig { returns(ValueType) }
    def casted_value
      T.cast(@value, ValueType)
    end
  end
end
