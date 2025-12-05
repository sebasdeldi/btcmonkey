# Configure Rack Attack for rate limiting and throttling
# https://github.com/rack/rack-attack

class Rack::Attack
  # Allow requests from localhost in development
  safelist('allow-localhost') do |req|
    Rails.env.development? && ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Throttle spot purchases to prevent abuse
  # Allow 10 spot purchase attempts per minute per IP
  throttle('spots/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/game_sessions/:game_session_id/spots' && req.post?
  end

  # Throttle credit purchases to prevent abuse
  # Allow 5 credit purchase attempts per minute per IP
  throttle('credit_purchases/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/credit_purchases' && req.post?
  end

  # Throttle login attempts
  # Allow 5 login attempts per minute per IP
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end

  # Throttle registration attempts
  # Allow 3 registrations per hour per IP
  throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Exponential backoff for repeat offenders
  # Ban IPs that hit rate limits more than 5 times in 10 minutes
  blocklist('repeated-limit-hits') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 5, findtime: 10.minutes, bantime: 1.hour) do
      # Track how many times this IP has been throttled
      Rack::Attack.cache.count("#{req.ip}:limit-hit", 10.minutes) > 5
    end
  end

  # Custom throttle response
  self.throttled_responder = lambda do |env|
    retry_after = env['rack.attack.match_data'][:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
    ]
  end

  # Custom blocklist response
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Your IP has been blocked due to suspicious activity.' }.to_json]
    ]
  end

  # Track requests that hit rate limits (for monitoring)
  ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} #{req.path} (#{payload[:matched]})"
  end

  # Track blocked requests
  ActiveSupport::Notifications.subscribe('blocklist.rack_attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.error "[Rack::Attack] Blocked: #{req.ip} #{req.path} (#{payload[:matched]})"
  end
end
