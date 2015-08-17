require_relative './tsquery'
require 'delegate'


# Inspired by https://rubytapas.dpdcart.com/subscriber/post?id=689
class RetryingTsquery < DelegateClass(Tsquery)
  def connect(times: 3, sleep: Kernel.method(:sleep), **keyword_args)
    super(**keyword_args)
  rescue Errno::ECONNREFUSED
    sleep.call 0.5
    retry if (times -= 1) > 0
    Kernel.raise
  end


  def execute(*args, times: 3, sleep: Kernel.method(:sleep), **keyword_args)
    super(*args, **keyword_args)
  rescue Tsquery::UnknownCommand
    Kernel.raise
  rescue Tsquery::Error
    sleep.call 0.5
    retry if (times -= 1) > 0
    Kernel.raise
  end


  # Needed for the delegation to work.


  def method_missing(command, *args)
    execute(command.to_s, *args)
  end


  def respond_to_missing?(command, *)
    !!(command =~ /[[:alnum:]]$/)
  end


  def inspect
    __getobj__.inspect
  end
end
