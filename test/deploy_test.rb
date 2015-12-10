require 'test_helper'

class DeployTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::Deploy::VERSION
  end


  def test_it_requires_arguments
    exception = assert_raises(ArgumentError) { Deploy::Runner.new }
    assert_equal("wrong number of arguments (0 for 1)", exception.message)
  end

  def test_it_accepts_one_argument
    assert_instance_of Deploy::Runner, Deploy::Runner.new(tag)
  end

  def test_it_only_accepts_one_argument
    exception = assert_raises(ArgumentError) { Deploy::Runner.new(*list) }
    assert_match /wrong number of arguments \([\d]+ for 1\)/, exception.message
  end

  private
  def max_rand
    100
  end

  def tag
    tag = rand(max_rand)
  end

  def list
    Array.new(rand(max_rand)+2).map!{rand max_rand}
  end
end
