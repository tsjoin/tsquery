require_relative './tsquery'
require 'delegate'


# LazyTsquery delays the connection and the execution of
# following commands (`use`, `login`) until another command
# is executed.
# This allows to create ready-to-use Tsquery objects without
# ever hitting the server.
class LazyTsquery < DelegateClass(Tsquery)
  def connect(lazy: true, **kwargs)
    if lazy
      @connection_info = kwargs
      nil
    else
      super(**kwargs)
    end
  end


  def execute(command, *args)
    case command
    when 'use', 'login'
      @commands ||= []
      @commands << [command, args]

      nil
    else
      connect **@connection_info, lazy: false

      @commands.each do |command, args|
        super(command, *args)
      end
      @commands = []

      super
    end
  end


  # Needed for the delegation to work.


  def method_missing(command, *args)
    execute(command.to_s, *args)
  end


  def respond_to_missing?(command, *)
    !!(command =~ /[[:alnum:]]$/)
  end


  def login(username: 'serveradmin', password:)
    execute 'login', username, password
    nil
  rescue Tsquery::Error
    false
  end


  def inspect
    __getobj__.inspect
  end


  def close
    __getobj__.close
  rescue NoMethodError
  end
end
