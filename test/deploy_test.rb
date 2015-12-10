require 'test_helper'

class DeployTest < Minitest::Test
  TAG='3.14.15'

  def test_that_it_has_a_version_number
    refute_nil ::Deploy::VERSION
  end

  def test_that_it_requires_arguments
    exception = assert_raises(ArgumentError) { Deploy::Runner.new }
    assert_equal "wrong number of arguments (0 for 1)", exception.message
  end

  def test_that_it_accepts_one_argument
    assert_instance_of Deploy::Runner, Deploy::Runner.new(TAG)
  end

  def test_that_it_only_accepts_one_argument
    exception = assert_raises(ArgumentError) { Deploy::Runner.new(TAG, TAG) }
    assert_match /wrong number of arguments \([\d]+ for 1\)/, exception.message
  end
end
