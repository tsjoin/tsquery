# tsquery
> Automate your TeamSpeak 3 server with Ruby!
Learn about TeamSpeak 3 ServerQuery [here](http://media.teamspeak.com/ts3_literature/TeamSpeak%203%20Server%20Query%20Manual.pdf).

## Tsquery
```ruby
tsquery = Tsquery.new
tsquery.connect server: "127.0.0.1"

tsquery.use 1
tsquery.login password: "password"
tsquery.serveredit virtualserver_name: "My TeamSpeak 3 Server"
tsquery.close
```

## LazyTsquery
Using Tsquery automated? Delay the connection as long as possible:
```ruby
tsquery = LazyTsquery.new(Tsquery.new)
tsquery.connect server: "127.0.0.1"

# `use` and `login` are delayed as long as possible.
tsquery.use 1
tsquery.login password: "password"

# Now we are hitting the server!
tsquery.serveredit virtualserver_name: "My TeamSpeak 3 Server"
tsquery.close
```

The following example will never connect to the server.
```ruby
tsquery = LazyTsquery.new(Tsquery.new)
tsquery.connect server: "127.0.0.1"

tsquery.use 1
tsquery.login password: "password"
tsquery.close
```

## RetryingTsquery
💩y connection? Retry failing commands:
```ruby
tsquery = RetryingTsquery.new(Tsquery.new)
# `connect` will be retried up to 3 times.
tsquery.connect server: "127.0.0.1"

tsquery.use 1
tsquery.login password: "password"

# `serveredit` and other commands will be retried too!
tsquery.serveredit virtualserver_name: "My TeamSpeak 3 Server"
tsquery.close
```

## I want it all!
```ruby
tsquery = LazyTsquery.new(RetryingTsquery.new(Tsquery.new))
# ...
```

## Contributing

1. Fork it ( https://github.com/tsjoin/tsquery/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
