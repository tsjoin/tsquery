require_relative './test_helper'


class TsqueryTest < Minitest::Test
  def setup
    @telnet = telnet = Minitest::Mock.new
    @telnet_class = Class.new do
      define_singleton_method :new do |*|
        telnet
      end
    end

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]

    @tsquery = Tsquery.new(logger: Logger.new(nil))
    @tsquery.connect telnet_class: @telnet_class
  end


  def test_execute_simple_command
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'quit', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.execute 'quit'
  end


  def test_execute_unknown_command
    @telnet.expect :cmd, 'error id=256 msg=command\snot\sfound', ['String' => 'unknown', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    assert_raises Tsquery::UnknownCommand do
      @tsquery.execute 'unknown'
    end
  end


  def test_execute_simple_command_with_args
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'login serveradmin password', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.execute 'login', 'serveradmin', 'password'
  end


  def test_execute_complex_command_with_args
    command = 'serveredit virtualserver_name=tsjoin virtualserver_welcomemessage=Welcome\smessage'
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => command, 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.execute 'serveredit',
      'virtualserver_name' => 'tsjoin',
      'virtualserver_welcomemessage' => 'Welcome message'
  end


  def test_execute_command_with_symbol_args
    command = 'serveredit virtualserver_name=tsjoin virtualserver_welcomemessage=Welcome\smessage'
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => command, 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.execute 'serveredit',
      virtualserver_name: 'tsjoin',
      virtualserver_welcomemessage: 'Welcome message'
  end


  def test_execute_command_with_numeric_args
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'serverstop sid=1', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.execute 'serverstop', sid: 1
  end


  def test_execute_commands_are_logged
    logger = Minitest::Mock.new
    logger.expect :info, nil, ['=> serverstop sid=1']
    logger.expect :info, nil, ['<= error id=0 msg=ok']

    @telnet.expect :waitfor, nil, ['Match' => /^TS3\n/]
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'serverstop sid=1', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery = Tsquery.new(logger: logger)
    @tsquery.connect telnet_class: @telnet_class
    @tsquery.execute 'serverstop', sid: 1
    logger.verify
  end


  def test_execute_failing_command
    @telnet.expect :cmd, nil, ['String' => 'serverstop sid=1', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    assert_raises Tsquery::Error do
      @tsquery.serverstop sid: 1
    end
  end


  def test_execute_command_which_returns_properties
    @telnet.expect :cmd, <<-RESPONSE.gsub(/^\s*/, ''), ['String' => 'instanceinfo', 'Timeout' => 3, 'Match' => /error id=\d+/]
      serverinstance_database_version=23 serverinstance_filetransfer_port=30033
      error id=0 msg=ok
    RESPONSE

    assert_kind_of Hash, properties = @tsquery.instanceinfo
    assert_equal 23, properties.fetch('serverinstance_database_version')
  end


  def test_execute_command_which_returns_a_list
    @telnet.expect :cmd, <<-RESPONSE.gsub(/^\s*/, ''), ['String' => 'clientlist', 'Timeout' => 3, 'Match' => /error id=\d+/]
      clid=1 cid=1 client_database_id=2 client_nickname=mario client_type=0|clid=5 cid=1 client_database_id=1 client_nickname=serveradmin\\sfrom\\s127.0.0.1:10011 client_type=1
      error id=0 msg=ok
    RESPONSE

    assert_kind_of Array, clients = @tsquery.clientlist
    assert_equal 2, clients.count
    assert_equal 'mario', clients.first.fetch('client_nickname')
  end


  def test_execute_command_which_returns_a_list_including_only_a_key
    @telnet.expect :cmd, <<-RESPONSE.gsub(/^\s*/, ''), ['String' => 'serverinfo', 'Timeout' => 3, 'Match' => /error id=\d+/]
      virtualserver_ip virtualserver_weblist_enabled=1 virtualserver_ask_for_privilegekey=0
      error id=0 msg=ok
    RESPONSE

    assert_kind_of Hash, serverinfo = @tsquery.serverinfo
    assert_nil serverinfo.fetch('virtualserver_ip')
  end


  def test_login
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'login serveradmin password', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    assert @tsquery.login(password: 'password')
  end


  def test_failing_login
    @telnet.expect :cmd, 'error id=520 msg=invalid\sloginname\sor\spassword', ['String' => 'login serveradmin wrong', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    refute @tsquery.login(password: 'wrong')
  end


  def test_method_missing
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => 'logout', 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.logout
  end


  def test_method_missing_with_arguments
    command = 'serveredit virtualserver_name=tsjoin virtualserver_welcomemessage=Welcome\smessage'
    @telnet.expect :cmd, 'error id=0 msg=ok', ['String' => command, 'Timeout' => 3, 'Match' => /^error id=\d+/]

    @tsquery.serveredit 'virtualserver_name' => 'tsjoin', 'virtualserver_welcomemessage' => 'Welcome message'
  end


  def test_close
    @telnet.expect :close, nil, []

    @tsquery.close
  end


  def teardown
    @telnet.verify
  end
end
