module GameSessionsHelper
  # Maximum number of spots that can be purchased at once
  MAX_SPOTS_PER_PURCHASE = 10

  # Returns an array of [label, value] pairs for quantity selection
  def spot_quantity_options(game_session)
    max_purchasable = [game_session.spots_remaining, MAX_SPOTS_PER_PURCHASE].min
    (1..max_purchasable).map { |n| [n, n] }
  end
end
