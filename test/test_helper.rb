ENV['ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require_relative '../lib/tsquery'
require_relative '../lib/lazy_tsquery'
require_relative '../lib/retrying_tsquery'
