require 'net/telnet'
require 'logger'


class Tsquery
  def initialize(logger: Logger.new(STDOUT))
    @logger = logger
  end


  def execute(command, *args)
    args = args.each_with_object([]) do |arg, array|
      case arg
      when Integer
        array << arg.to_s
      when String
        array << arg
      when Hash
        arg.each do |key, value|
          array << "#{key}=#{value.to_s.gsub(ESCAPE_PATTERNS_REGEXP, ESCAPE_PATTERNS)}"
        end
      end
    end

    full_command = ([command] + args).join(' ')
    @logger.info "=> #{full_command}"

    case command
    when /list$/
      parse_list(@telnet.cmd(
        'String'  => full_command,
        'Timeout' => 3,
        'Match'   => /error id=\d+/
      ))
    when /info$/, 'whoami', 'version'
      parse_info(@telnet.cmd(
        'String'  => full_command,
        'Timeout' => 3,
        'Match'   => /error id=\d+/
      ))
    else
      parse(@telnet.cmd(
        'String'  => full_command,
        'Timeout' => 3,
        'Match'   => /^error id=\d+/
      ))
    end
  end


  def login(username: 'serveradmin', password:)
    execute 'login', username, password
    true
  rescue Error
    false
  end


  def method_missing(command, *args)
    execute(command.to_s, *args)
  end


  def respond_to_missing?(command, *)
    !!(command =~ /[[:alnum:]]$/)
  end


  def connect(server: '127.0.0.1', port: '10011', telnet_class: Net::Telnet)
    @telnet = telnet_class.new('Host' => server, 'Port' => port, 'Waittime' => 0.1)
    @telnet.waitfor 'Match' => /^TS3\n/
  end


  def close
    @telnet.close
  end


private
  # Copied from http://addons.teamspeak.com/directory/addon/integration/TeamSpeak-3-PHP-Framework.html
  ESCAPE_PATTERNS = {
    "/"  => "\\/", # slash
    " "  => "\\s", # whitespace
    "|"  => "\\p", # pipe
    ";"  => "\\;", # semicolon
    "\a" => "\\a", # bell
    "\b" => "\\b", # backspace
    "\f" => "\\f", # formfeed
    "\n" => "\\n", # newline
    "\r" => "\\r", # carriage return
    "\t" => "\\t", # horizontal tab
    "\v" => "\\v", # vertical tab
    "\\" => "\\\\" # backslash
  }.freeze
  ESCAPE_PATTERNS_REGEXP = Regexp.union(ESCAPE_PATTERNS.keys).freeze

  INVERTED_ESCAPE_PATTERNS = ESCAPE_PATTERNS.invert.freeze
  INVERTED_ESCAPE_PATTERNS_REGEXP = Regexp.union(INVERTED_ESCAPE_PATTERNS.keys).freeze


  def parse_list(response)
    check_response! response

    first, last = response.split(/\n\r?/)
    @logger.info "<= #{first}"
    parse last

    first.split('|').map do |arguments|
      deserialize_arguments(arguments)
    end
  end


  def parse_info(response)
    check_response! response

    first, last = response.split(/\n\r?/)
    @logger.info "<= #{first}"
    parse last

    deserialize_arguments(first)
  end


  def parse(response)
    check_response! response

    @logger.info "<= #{response}"

    # Response always starts with "error", so we just remove it
    response = response.gsub(/^error\s/, '')
    arguments = deserialize_arguments(response)

    raise Error, arguments['msg'] if Integer(arguments['id']) != 0
    arguments['msg'] == 'ok'
  end


  def deserialize_arguments(string)
    string.split.each_with_object({}) do |string, hash|
      key, value = string.split('=')
      value = value.gsub(INVERTED_ESCAPE_PATTERNS_REGEXP, INVERTED_ESCAPE_PATTERNS)

      hash[key] = case value
      when /^\d+$/
        value.to_i
      when /^\d+\.\d+$/
        value.to_f
      else
        value
      end
    end
  end


  def check_response!(response)
    raise Error, 'response is nil' if response.nil?
    raise UnknownCommand, deserialize_arguments(response.gsub(/^error\s/, ''))['msg'] if response =~ /error id=256\D/
  end


  class Error < StandardError; end
  class UnknownCommand < Error; end
end
