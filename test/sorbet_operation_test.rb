# typed: strict
# frozen_string_literal: true

require "test_helper"

class SorbetOperationTest < Minitest::Test
  describe SorbetOperation do
    it "has a version number" do
      refute_nil(::SorbetOperation::VERSION)
    end

    describe "default logger" do
      before do
        ::SorbetOperation.default_logger = nil
      end

      it "has a default logger" do
        logger = ::SorbetOperation.default_logger

        refute_nil(logger)
        assert_instance_of(::Logger, logger)
      end

      it "can set a default logger" do
        logger = ::Logger.new($stderr)

        ::SorbetOperation.default_logger = logger

        refute_nil(::SorbetOperation.default_logger)
        assert_equal(logger, ::SorbetOperation.default_logger)
      end
    end
  end
end
