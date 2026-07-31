require "test_helper"

class ApplicationConfigurationTest < ActiveSupport::TestCase
  test "supports Solid Queue fiber workers" do
    configuration = SolidQueue::Configuration.new

    assert_equal :fiber, ActiveSupport::IsolatedExecutionState.isolation_level
    assert configuration.valid?, configuration.errors.full_messages.to_sentence
  end
end
