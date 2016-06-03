# frozen_string_literal: true
require_relative './test_helper'

class LazyTsqueryTest < Minitest::Test
  def setup
    @telnet = telnet = Minitest::Mock.new
    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        telnet
      end
    end

    @tsquery = LazyTsquery.new(Tsquery.new(logger: Logger.new(nil)))
  end

  def test_it_delays_execution
    @tsquery.connect telnet_class: @telnet_class
    @tsquery.use 1
    @tsquery.login password: 'password'
  end

  def test_it_executes_if_necessary
    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'use 1', 'Timeout' => 3, 'Match' => /^error id=\d+/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'login serveradmin password', 'Timeout' => 3, 'Match' => /^error id=\d+/]
    @telnet.expect :cmd, <<-RESPONSE.gsub(/^\s*/, ''), ['String' => 'version', 'Timeout' => 3, 'Match' => /error id=\d+/]
      version=3.0.0-alpha4 build=9155 platform=Linux
      error id=0 msg=ok
    RESPONSE

    @tsquery.connect telnet_class: @telnet_class
    @tsquery.use 1
    @tsquery.login password: 'password'
    @tsquery.version
  end

  def test_delayed_methods_return_nil
    assert_nil @tsquery.connect telnet_class: @telnet_class
    assert_nil @tsquery.use 1
    assert_nil @tsquery.login password: 'password'
  end

  def test_inspect
    assert_equal @tsquery.inspect, @tsquery.__getobj__.inspect
  end

  def test_close
    @tsquery.close
  end

  def teardown
    assert @telnet.verify
  end
end
