# typed: strict
# frozen_string_literal: true

require "test_helper"

require "logger"

class BaseTest < Minitest::Test
  # `SorbetOperation::Base` is an abstract class that is difficult to test
  # directly. We can test it indirectly by creating a subclass that implements
  # the abstract methods.
  class DivideTwoNumbers < SorbetOperation::Base
    ValueType = type_member { { fixed: Float } }

    sig { params(dividend: Numeric, divisor: Numeric).void }
    def initialize(dividend, divisor)
      super()
      @dividend = dividend
      @divisor = divisor
    end

    protected

    sig { override.returns(Float) }
    def execute
      if @divisor.zero?
        raise SorbetOperation::Failure, "Divisor cannot be zero"
      end

      logger.info("Dividing #{@dividend} by #{@divisor}")

      @dividend.to_f / @divisor.to_f
    end
  end

  describe SorbetOperation::Base do
    before do
      SorbetOperation.default_logger = ::Logger.new(::IO::NULL)
    end

    describe "#perform" do
      describe "on success" do
        it "returns a successful result" do
          result = DivideTwoNumbers.new(10.0, 2.0).perform

          assert_predicate(result, :success?)
          assert_in_delta(5.0, result.unwrap!)
        end

        it "logs debug messages" do
          log_buf = ::StringIO.new
          logger = ::Logger.new(log_buf, level: ::Logger::DEBUG)
          logger.formatter = ->(_severity, _datetime, _progname, msg) { "#{msg}\n" }

          op = DivideTwoNumbers.new(10.0, 2.0)
          op.logger = logger

          op.perform

          log_lines = log_buf.string.lines

          assert_operator(log_lines.count, :>=, 2)
          assert_equal("Performing operation BaseTest::DivideTwoNumbers", T.must(log_lines.first).chomp)
          assert_equal(
            "Operation BaseTest::DivideTwoNumbers succeeded, return value = 5.0",
            T.must(log_lines.last).chomp,
          )
        end
      end

      describe "on failure" do
        it "returns a failed result when the operation fails" do
          result = DivideTwoNumbers.new(10.0, 0.0).perform

          assert_predicate(result, :failure?)
          assert_equal("Divisor cannot be zero", result.unwrap_error!.message)
        end

        it "logs debug messages" do
          log_buf = ::StringIO.new
          logger = ::Logger.new(log_buf, level: ::Logger::DEBUG)
          logger.formatter = ->(_severity, _datetime, _progname, msg) { "#{msg}\n" }

          op = DivideTwoNumbers.new(10.0, 0.0)
          op.logger = logger

          op.perform

          log_lines = log_buf.string.lines

          assert_operator(log_lines.count, :>=, 2)
          assert_equal("Performing operation BaseTest::DivideTwoNumbers", T.must(log_lines.first).chomp)
          assert_equal(
            "Operation BaseTest::DivideTwoNumbers failed, failure = " \
              "#<SorbetOperation::Failure: Divisor cannot be zero>",
            T.must(log_lines.last).chomp,
          )
        end
      end
    end

    describe "#logger=" do
      it "accepts a logger" do
        log_buf = ::StringIO.new
        logger = ::Logger.new(log_buf, level: ::Logger::INFO)
        logger.formatter = ->(_severity, _datetime, _progname, msg) { "CUSTOM-LOGGER: #{msg}\n" }

        op = DivideTwoNumbers.new(10.0, 2.0)
        op.logger = logger

        op.perform

        log_lines = log_buf.string.lines

        assert_equal(1, log_lines.count)
        assert_equal("CUSTOM-LOGGER: Dividing 10.0 by 2.0", T.must(log_lines[0]).chomp)
      end
    end
  end
end
