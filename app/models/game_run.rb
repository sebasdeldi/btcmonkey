class GameRun < ApplicationRecord
  belongs_to :user
  belongs_to :game_session
  belongs_to :spot_purchase

  validates :seed, presence: true

  scope :unplayed, -> { where(completed_at: nil) }
  scope :played, -> { where.not(completed_at: nil) }
  scope :by_score, -> { order(score: :desc) }

  before_validation :generate_seed, on: :create

  def played?
    completed_at.present?
  end

  def play!(score_value, metadata = {})
    raise "Game already played" if played?
    # Score is now in milliseconds (10,000ms to 600,000ms valid range)
    raise "Score must be between 1 and 600000" unless (1..600_000).include?(score_value)

    update!(
      score: score_value,
      completed_at: Time.current,
      result_metadata: metadata.merge(
        played_at: Time.current.iso8601,
        client_seed: seed
      )
    )
  end

  private

  def generate_seed
    self.seed ||= SecureRandom.hex(16)
  end
end
