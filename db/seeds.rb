# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Credit Packages
credit_packages = [
  { name: "Starter Pack", credits: 20, price_usd: 19.00, description: "Perfect for trying out the platform" },
  { name: "Popular Pack", credits: 50, price_usd: 39.00, description: "Most popular choice - best value" },
  { name: "Pro Pack", credits: 100, price_usd: 69.00, description: "For power users" },
  { name: "Ultimate Pack", credits: 250, price_usd: 149.00, description: "Maximum credits at the best rate" }
]

credit_packages.each do |package|
  CreditPackage.find_or_create_by!(name: package[:name]) do |cp|
    cp.credits = package[:credits]
    cp.price_usd = package[:price_usd]
    cp.description = package[:description]
    cp.active = true
  end
end

puts "Created #{CreditPackage.count} credit packages"

# Create Game Sessions
game_sessions = [
  # Win-100 sessions (3 sessions)
  {
    game_session_type: "win-100",
    name: "Quick Win 100",
    description: "Fast-paced game with 100 credits prize pool. 10 spots available!",
    price_in_credits: 10,
    max_spots: 10,
    platform_fee_in_credits: 5,
    expected_award_in_credits: 95
  },
  {
    game_session_type: "win-100",
    name: "Sprint 100",
    description: "Race to win 100 credits! Quick entry, quick rewards.",
    price_in_credits: 10,
    max_spots: 10,
    platform_fee_in_credits: 5,
    expected_award_in_credits: 95
  },
  {
    game_session_type: "win-100",
    name: "Mini Jackpot 100",
    description: "Small bet, big excitement. Win up to 100 credits!",
    price_in_credits: 10,
    max_spots: 10,
    platform_fee_in_credits: 5,
    expected_award_in_credits: 95
  },

  # Win-1000 sessions (3 sessions)
  {
    game_session_type: "win-1000",
    name: "Mega Win 1000",
    description: "Mid-tier jackpot with 1000 credits up for grabs!",
    price_in_credits: 100,
    max_spots: 10,
    platform_fee_in_credits: 50,
    expected_award_in_credits: 950
  },
  {
    game_session_type: "win-1000",
    name: "Championship 1000",
    description: "Compete for the championship prize of 1000 credits.",
    price_in_credits: 100,
    max_spots: 10,
    platform_fee_in_credits: 50,
    expected_award_in_credits: 950
  },
  {
    game_session_type: "win-1000",
    name: "Golden Opportunity 1000",
    description: "Your golden chance to win big - 1000 credits awaiting!",
    price_in_credits: 100,
    max_spots: 10,
    platform_fee_in_credits: 50,
    expected_award_in_credits: 950
  },

  # Win-10000 sessions (3 sessions)
  {
    game_session_type: "win-10000",
    name: "Ultimate Jackpot 10K",
    description: "The biggest prize pool - 10,000 credits! Are you ready?",
    price_in_credits: 1000,
    max_spots: 10,
    platform_fee_in_credits: 500,
    expected_award_in_credits: 9500
  },
  {
    game_session_type: "win-10000",
    name: "Grand Prize 10K",
    description: "The grand daddy of them all. Win 10,000 credits!",
    price_in_credits: 1000,
    max_spots: 10,
    platform_fee_in_credits: 500,
    expected_award_in_credits: 9500
  },
  {
    game_session_type: "win-10000",
    name: "Elite Championship 10K",
    description: "For elite players only. Massive 10,000 credit prize!",
    price_in_credits: 1000,
    max_spots: 10,
    platform_fee_in_credits: 500,
    expected_award_in_credits: 9500
  }
]

game_sessions.each do |session|
  GameSession.find_or_create_by!(game_session_type: session[:game_session_type], name: session[:name]) do |gs|
    gs.description = session[:description]
    gs.price_in_credits = session[:price_in_credits]
    gs.max_spots = session[:max_spots]
    gs.platform_fee_in_credits = session[:platform_fee_in_credits]
    gs.expected_award_in_credits = session[:expected_award_in_credits]
    gs.started_at = Time.current
    gs.status = :active
  end
end

puts "Created #{GameSession.count} game sessions (#{GameSession.where(game_session_type: 'win-100').count} win-100, #{GameSession.where(game_session_type: 'win-1000').count} win-1000, #{GameSession.where(game_session_type: 'win-10000').count} win-10000)"
