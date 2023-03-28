# typed: strict
# frozen_string_literal: true

require "test_helper"

class ResultTest < Minitest::Test
  describe SorbetOperation::Result do
    describe "for a successful result" do
      before do
        @result = T.let(SorbetOperation::Result[Numeric].new(true, 234, nil), SorbetOperation::Result[Numeric])
      end

      describe "#success?" do
        it "returns true" do
          assert_predicate(@result, :success?)
        end
      end

      describe "#failure?" do
        it "returns false" do
          refute_predicate(@result, :failure?)
        end
      end

      describe "#unwrap!" do
        it "returns the value" do
          assert_equal(234, @result.unwrap!)
        end
      end

      describe "#safe_unwrap" do
        it "returns the value" do
          assert_equal(234, @result.safe_unwrap)
        end
      end

      describe "#unwrap_or" do
        it "returns the success value" do
          value = @result.unwrap_or(456)

          assert_equal(234, value)
        end
      end

      describe "#unwrap_or_else" do
        it "returns the value and does not call the block" do
          block_called = T.let(false, T::Boolean)

          value = @result.unwrap_or_else do
            block_called = true
            456
          end

          assert_equal(234, value)
          refute(block_called)
        end
      end

      describe "#unwrap_error!" do
        it "raises " do
          e = assert_raises(RuntimeError) do
            @result.unwrap_error!
          end

          refute_nil(e)
          assert_equal("Called `unwrap_err!` on a success", e.message)
        end
      end

      describe "#safe_unwrap_error" do
        it "returns nil" do
          assert_nil(@result.safe_unwrap_error)
        end
      end

      describe "#on_success" do
        it "yields the value" do
          value = T.let(nil, T.nilable(Numeric))

          @result.on_success { |v| value = v }

          refute_nil(value)
          assert_equal(234, value)
        end
      end

      describe "#on_failure" do
        it "does not call the block" do
          block_called = T.let(false, T::Boolean)

          @result.on_failure { |_e| block_called = true }

          refute(block_called)
        end
      end

      describe "chaining callbacks" do
        it "supports chaining callbacks" do
          value = T.let(nil, T.nilable(Numeric))
          error = T.let(nil, T.nilable(SorbetOperation::Failure))
          on_success_called = T.let(false, T::Boolean)
          on_failure_called = T.let(false, T::Boolean)

          @result
            .on_success do |v|
              on_success_called = true
              value = v
            end
            .on_failure do |e|
              on_failure_called = true
              error = e
            end

          assert(on_success_called)
          refute_nil(value)
          assert_equal(234, value)
          refute(on_failure_called)
          assert_nil(error)
        end
      end
    end

    describe "for a failure result" do
      before do
        @result = T.let(
          SorbetOperation::Result[Numeric].new(false, nil, SorbetOperation::Failure.new("Argh")),
          SorbetOperation::Result[Numeric],
        )
      end

      describe "#success?" do
        it "returns false" do
          refute_predicate(@result, :success?)
        end
      end

      describe "#failure?" do
        it "returns true" do
          assert_predicate(@result, :failure?)
        end
      end

      describe "#unwrap!" do
        it "raises the error" do
          e = assert_raises(SorbetOperation::Failure) { @result.unwrap! }

          assert_equal("Argh", e.message)
        end
      end

      describe "#safe_unwrap" do
        it "returns nil" do
          assert_nil(@result.safe_unwrap)
        end
      end

      describe "#unwrap_or" do
        it "returns the default value" do
          value = @result.unwrap_or(456)

          assert_equal(456, value)
        end
      end

      describe "#unwrap_or_else" do
        it "calls the block and returns its value" do
          block_called = T.let(false, T::Boolean)

          value = @result.unwrap_or_else do
            block_called = true
            456
          end

          assert_equal(456, value)
          assert(block_called)
        end
      end

      describe "#unwrap_error!" do
        it "returns the error" do
          e = @result.unwrap_error!

          refute_nil(e)
          assert_instance_of(SorbetOperation::Failure, e)
          assert_equal("Argh", e.message)
        end
      end

      describe "#safe_unwrap_error" do
        it "returns nil" do
          e = @result.safe_unwrap_error

          refute_nil(e)
          e = T.must(e)

          assert_instance_of(SorbetOperation::Failure, e)
          assert_equal("Argh", e.message)
        end
      end

      describe "#on_success" do
        it "does not call the block" do
          block_called = T.let(false, T::Boolean)

          @result.on_success { |_v| block_called = true }

          refute(block_called)
        end
      end

      describe "#on_failure" do
        it "yields the error" do
          error = T.let(nil, T.nilable(SorbetOperation::Failure))

          @result.on_failure { |e| error = e }

          refute_nil(error)
          error = T.must(error)

          assert_instance_of(SorbetOperation::Failure, error)
          assert_equal("Argh", error.message)
        end
      end

      describe "chaining callbacks" do
        it "supports chaining callbacks" do
          value = T.let(nil, T.nilable(Numeric))
          error = T.let(nil, T.nilable(SorbetOperation::Failure))
          on_success_called = T.let(false, T::Boolean)
          on_failure_called = T.let(false, T::Boolean)

          @result
            .on_success do |v|
              on_success_called = true
              value = v
            end
            .on_failure do |e|
              on_failure_called = true
              error = e
            end

          refute(on_success_called)
          assert_nil(value)
          assert(on_failure_called)
          refute_nil(error)
          error = T.must(error)

          assert_instance_of(SorbetOperation::Failure, error)
          assert_equal("Argh", error.message)
        end
      end
    end

    describe "constructor" do
      it "can construct a successful result" do
        # No assertions, we're just checking that this doesn't raise.
        SorbetOperation::Result[Numeric].new(true, 234, nil)
      end

      it "can construct a successful result with a nil value" do
        # No assertions, we're just checking that this doesn't raise.
        SorbetOperation::Result[T.nilable(String)].new(true, nil, nil)
      end

      it "can construct a failure result" do
        # No assertions, we're just checking that this doesn't raise.
        SorbetOperation::Result[Numeric].new(false, nil, SorbetOperation::Failure.new("Argh"))
      end

      it "raises if the success flag is true but the error is not nil" do
        e = assert_raises(ArgumentError) do
          SorbetOperation::Result[Numeric].new(true, 234, SorbetOperation::Failure.new("Argh"))
        end

        assert_equal("Cannot pass an error to a success result", e.message)
      end

      it "raises if the success flag is false but the value is not nil" do
        e = assert_raises(ArgumentError) do
          SorbetOperation::Result[Numeric].new(false, 234, SorbetOperation::Failure.new("Argh"))
        end

        assert_equal("Cannot pass a value to a failure result", e.message)
      end

      it "raises if the success flag is false but the error is nil" do
        e = assert_raises(ArgumentError) do
          SorbetOperation::Result[Numeric].new(false, nil, nil)
        end

        assert_equal("Must pass an error to a failure result", e.message)
      end
    end

    describe "using NilClass as the value type" do
      it "works as expected for a successful result" do
        result = SorbetOperation::Result[NilClass].new(true, nil, nil)

        assert_predicate(result, :success?)
        refute_predicate(result, :failure?)
        assert_nil(result.unwrap!)
      end
    end
  end
end
