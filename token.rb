require 'time'

# A generic expirable and refreshable token.
class Token
  class InvalidTokenError < StandardError; end
  class TokenNotRefreshableError < StandardError; end

  attr_reader :token
  attr_reader :expiration_date
  attr_reader :scope
  attr_reader :refresh_token

  # Initializes a new token.
  #
  # @param token [Any] The value of the token. This can be any type but is usually a String.
  # @param expiration_date [Time, DateTime, String] default: nil The date of expiration, or nil if the token does not expire.
  # @param expires_in_seconds [Int] default: nil The ttl in seconds, or nil if the token does not expire.
  # @param scope [Any] default: nil The scope of this token.
  # @param refresh_token [Token] default: nil An optional refresh token.
  # @return [Token]
  def initialize(token, expiration_date: nil, expires_in_seconds: nil, scope: nil, refresh_token: nil)
    if token.is_a? String
      @token = token
    else
      raise ArgumentError, 'Argument token should be a String'
    end

    if expiration_date && expires_in_seconds
      raise ArgumentError, 'You can provide either expiration_date or expires_in_seconds, but not both.'
    elsif expiration_date
      @expiration_date = to_time(expiration_date)
    elsif expires_in_seconds
      @expiration_date = Time.now + expires_in_seconds
    else
      @expiration_date = nil
    end

    @scope = scope

    if refresh_token.is_a? Token
      @refresh_token = refresh_token
    elsif refresh_token.is_a? String
      @refresh_token = Token.new(refresh_token)
    elsif refresh_token
      raise ArgumentError, 'Argument refresh_token should be nil, a Token, or a String'
    end
  end

  private def to_time(input)
    return nil if input.nil?

    return case input
    when Time then input
    when DateTime then input.to_time
    when String then Time.parse(input)
    # when Integer then Time.at(input)
    # when Float then Time.at(input)
    else raise ArgumentError, 'Date/Time values must be passed as Time, DateTime, or a String that can be parsed by Time.parse'
    end
  end

  # Returns a new token from the given hash.
  # This can be used together with `Token#to_h` to serialize/deserialize a token.
  # @param hash [Hash]
  # @return [Token]
  def self.from_hash(hash)
    Token.new(hash[:token],
      expiration_date: hash[:expiration_date],
      scope: hash[:scope],
      refresh_token: hash[:refresh_token] ? Token.from_hash(hash[:refresh_token]) : nil
    )
  end

  # Returns true if the token is valid. A token is considered valid if the token is not nil and not expired.
  # @return [Boolean]
  def valid?
    !token.nil? && !expired?
  end

  # Returns true if the token is invalid. Opposite of `Token#valid?`
  # @see [Token::valid?]
  # @return [Boolean]
  def invalid?
    !valid?
  end

  # Returns true if the token is expired.
  # @return [Boolean]
  def expired?
    expires? && @expiration_date < Time.now
  end

  # Returns true if the token has an expiration date.
  # @return [Boolean]
  def expires?
    return !@expiration_date.nil?
  end

  # Returns true if the token is refreshable. A token is considered refreshable if it has a valid refresh token.
  # @return [Boolean]
  def refreshable?
    return false if @refresh_token.nil?
    return @refresh_token.valid?
  end

  # Raises InvalidTokenError if the token is not valid.
  # @raise [InvalidTokenError]
  def validate!
    raise InvalidTokenError unless valid?
  end

  # Raises TokenNotRefreshableError if the token is not refreshable.
  # @raise [TokenNotRefreshableError]
  def validate_refreshable!
    raise TokenNotRefreshableError unless refreshable?
  end

  # Returns the string value of the token.
  # @return [String]
  def to_s
    @token
  end

  # Returns the string value of the token.
  # @return [String]
  def value
    @token
  end

  # Returns the seconds until the token expires, or nil if the token does not expire.
  # @return [Float|nil]
  def seconds_until_expiration
    return nil unless expires?
    @expiration_date - Time.now
  end

  # Returns a hash that can be used as argument to Token::from_hash.
  # @return [Hash]
  def to_h
    {
      token: token,
      expiration_date: expiration_date&.to_s,
      scope: scope,
      refresh_token: refresh_token&.to_h
    }
  end

  # Returns a hash that can be converted to json, resulting in an OAuth compatible response.
  # @return [Hash]
  def to_oauth_hash
    hash = {
      access_token: token,
      token_type: 'bearer',
      expires_in: seconds_until_expiration,
      scope: scope
    }

    if refresh_token
      hash.merge!({
        refresh_token: refresh_token.value,
        refresh_token_expires_in: refresh_token.seconds_until_expiration
      })
    end

    hash
  end
end
