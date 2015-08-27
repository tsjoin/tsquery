require_relative './test_helper'
require 'delegate'


class RetryingTsqueryTest < Minitest::Test
  def setup
    @telnet = telnet = Minitest::Mock.new
    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        telnet
      end
    end

    @tsquery = RetryingTsquery.new(Tsquery.new(logger: Logger.new(nil)))
  end


  def test_delegate_methods
    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'use 1', 'Timeout' => 3, 'Match' => /^error id=\d+/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'login serveradmin password', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.connect telnet_class: @telnet_class
    @tsquery.use 1
    assert @tsquery.login password: 'password'
  end


  def test_connect
    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]

    @tsquery.connect telnet_class: @telnet_class
  end


  def test_connect_retries_if_connection_is_refused
    telnet = @telnet
    times = 3

    failing_telnet_class = Class.new do
      define_singleton_method :new do |*|
        fail Errno::ECONNREFUSED if (times -= 1) > 0
        telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]

    @tsquery.connect telnet_class: failing_telnet_class, sleep: ->(_){}
  end


  def test_connect_gives_up_after_3_retries
    telnet = @telnet
    times = 4

    failing_telnet_class = Class.new do
      define_singleton_method :new do |*|
        fail Errno::ECONNREFUSED if (times -= 1) > 0
        telnet
      end
    end

    assert_raises Errno::ECONNREFUSED do
      @tsquery.connect telnet_class: failing_telnet_class, sleep: ->(_){}
    end
  end


  def test_execute
    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'use 1', 'Timeout' => 3, 'Match' => /^error id=\d+/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'login serveradmin password', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.connect telnet_class: @telnet_class
    @tsquery.use 1
    assert @tsquery.login password: 'password'
  end


  def test_execute_retries_if_failing
    times = 3

    failing_telnet = SimpleDelegator.new(@telnet)
    failing_telnet.define_singleton_method :cmd do |*args|
      # cmd will fail the first x times.
      return nil if (times -= 1) > 0

      __getobj__.cmd *args
      'error id=0 msg=ok'
    end

    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        failing_telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'use 1', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.connect telnet_class: @telnet_class
    @tsquery.execute 'use 1', sleep: ->(*){}
  end


  def test_execute_gives_up_after_3_retries
    times = 4

    failing_telnet = SimpleDelegator.new(@telnet)
    failing_telnet.define_singleton_method :cmd do |*args|
      # cmd will fail the first x times.
      return nil if (times -= 1) > 0

      __getobj__.cmd *args
      'error id=0 msg=ok'
    end

    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        failing_telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]

    @tsquery.connect telnet_class: @telnet_class

    assert_raises Tsquery::Error do
      @tsquery.execute 'login serveradmin password', sleep: ->(*){}
    end
  end


  def test_dynamic_execute_retries_if_failing
    times = 3

    failing_telnet = SimpleDelegator.new(@telnet)
    failing_telnet.define_singleton_method :cmd do |*args|
      # cmd will fail the first x times.
      return nil if (times -= 1) > 0

      __getobj__.cmd *args
      'error id=0 msg=ok'
    end

    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        failing_telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'use 1', 'Timeout' => 3, 'Match' => /^error id=\d+/]


    @tsquery.connect telnet_class: @telnet_class
    @tsquery.use 1, sleep: ->(*){}
  end


  def test_dynamic_execute_gives_up_after_3_retries
    times = 4

    failing_telnet = SimpleDelegator.new(@telnet)
    failing_telnet.define_singleton_method :cmd do |*args|
      # cmd will fail the first x times.
      return nil if (times -= 1) > 0

      __getobj__.cmd *args
      'error id=0 msg=ok'
    end

    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        failing_telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]

    @tsquery.connect telnet_class: @telnet_class

    assert_raises Tsquery::Error do
      @tsquery.use 1, sleep: ->(*){}
    end
  end


  def test_does_not_retry_unknown_commands
    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=256 msg=command\snot\sfound', ['String' => 'unknown', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.connect telnet_class: @telnet_class

    ex = assert_raises Tsquery::UnknownCommand do
      @tsquery.execute 'unknown', sleep: ->(*){}
    end
    assert_equal 'command not found', ex.message
  end


  def test_inspect
    assert_equal @tsquery.inspect, @tsquery.__getobj__.inspect
  end


  def teardown
    assert @telnet.verify
  end
end
