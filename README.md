# token.rb

A small Ruby lib that provides a Token class for a generic expirable and refreshable token.

## Usage

### Creating a token:
```ruby

# A token that never expires
token = Token.new('abcdefg')
token.to_s # abcdefg

# With a fixed expiration date or an expiration in seconds from now
tomorrow = Time.now + 86400
token = Token.new('abcdefg', expiration_date: tomorrow)
token = Token.new('abcdefg', expires_in_seconds: 3600)

# With a scope
token = Token.new('abcdefg', scope: 'readuser readposts')

# With a refresh token
refresh_token = Token.new('1234', expires_in_seconds: 604800)
token = Token.new('abcdefg', refresh_token: refresh_token)

# Combined
tomorrow = Time.now + 86400
refresh_token = Token.new('1234', expires_in_seconds: 604800)
token = Token.new('abcdefg', expiration_date: tomorrow, scope: 'readuser readposts', refresh_token: refresh_token)
```

The Token class does not care what the values of the token and the scope are. You can use strings, numbers, arrays, or whatever you need for your use case.

### Persisting a token
```ruby
token = Token.new('abcdefg')
hash = token.to_h
# You can serialize and save the hash somewhere, then load it later as follows
token = Token.from_hash(hash)
```

### Querying a token
```ruby
refresh_token = Token.new('1234')
token = Token.new('abcdefg', expiration_date: tomorrow, scope: 'readuser readposts', refresh_token: refresh_token)

token.valid? # true
token.invalid? # false
token.expired? # false
token.expires? # true
token.refreshable? # true
token.validate! # Raises InvalidTokenError if valid? is false
token.validate_refreshable! # Raises TokenNotRefreshableError if refreshable? is false
token.to_s # abcdefg

token.refresh_token.valid? # true
token.refresh_token.invalid? # false
token.refresh_token.expired? # false
token.refresh_token.expires? # false
token.refresh_token.refreshable? # false
token.refresh_token.validate! # Raises InvalidTokenError if valid? is false
token.refresh_token.validate_refreshable! # Raises TokenNotRefreshableError if refreshable? is false
token.refresh_token.to_s # 1234
