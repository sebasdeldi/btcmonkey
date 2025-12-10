# Service for number sequence memory game logic, validation, and scoring
# Handles deterministic grid generation, score calculation, and anti-cheat detection
class NumberSequenceGameService
  attr_reader :seed, :errors

  # Validation constants
  MIN_VALID_TIME = 10.0        # 10 seconds minimum (25 clicks < 10s is superhuman)
  MAX_VALID_TIME = 600.0       # 10 minutes maximum
  MIN_AVG_CLICK_INTERVAL = 0.3 # 0.3 seconds per click minimum average
  PERFECT_TIME = 15.0          # 15 seconds or less = 100 points

  def initialize(seed)
    @seed = seed
    @random = Random.new(seed.to_i(16)) # Convert hex seed to deterministic integer
    @errors = []
  end

  # Generate deterministic 5x5 grid layout
  # Returns hash mapping numbers to [row, col] positions
  # Example: { 1 => [0, 0], 2 => [1, 3], ..., 25 => [4, 4] }
  def generate_grid_layout
    # Generate positions 0-24 and shuffle deterministically using seed
    positions = (0..24).to_a.shuffle(random: @random)
    layout = {}

    # Map each number (1-25) to a grid position
    (1..25).each_with_index do |number, index|
      position = positions[index]
      row = position / 5  # Integer division for row
      col = position % 5  # Modulo for column
      layout[number] = [row, col]
    end

    layout
  end

  # Validate that click sequence is exactly [1, 2, 3, ..., 25]
  def validate_sequence(clicks)
    clicks == (1..25).to_a
  end

  # Calculate score based on completion time in milliseconds
  # Score = time in milliseconds (lower is better)
  # This provides precise competitive scoring where every millisecond counts
  # - Minimum valid time: 10,000ms (10 seconds)
  # - Maximum valid time: 600,000ms (10 minutes)
  # - Over 600 seconds: returns penalty score of 1,999,999ms
  def calculate_score(time_seconds)
    time_ms = (time_seconds * 1000).round

    # Return penalty score if time limit exceeded
    return 1_999_999 if time_seconds > MAX_VALID_TIME

    # Return milliseconds as score
    time_ms
  end

  # Detect cheating patterns
  # Returns error message string if cheating detected, nil otherwise
  def detect_cheating(time_seconds, click_count, timestamps)
    # Check: Completion time too fast
    return "Completion time impossibly fast" if time_seconds < MIN_VALID_TIME

    # Check: Wrong number of clicks
    return "Invalid click count (expected 25)" unless click_count == 25

    # Check: Timestamps must be sequential (monotonically increasing)
    return "Timestamps must be sequential" unless timestamps_sequential?(timestamps)

    # Check: Average click speed isn't superhuman
    return "Click speed impossibly fast" if avg_click_too_fast?(time_seconds)

    # Check: Click pattern isn't suspiciously uniform (likely scripted)
    return "Suspicious click pattern detected" if pattern_too_uniform?(timestamps)

    nil # No cheating detected
  end

  private

  # Check if timestamps are monotonically increasing
  def timestamps_sequential?(timestamps)
    return true if timestamps.empty? || timestamps.length == 1

    timestamps.each_cons(2).all? { |a, b| b > a }
  end

  # Check if average click speed is impossibly fast
  def avg_click_too_fast?(time_seconds)
    (time_seconds / 25.0) < MIN_AVG_CLICK_INTERVAL
  end

  # Check if click pattern is too uniform (likely scripted)
  # Humans have natural variation in click timing
  def pattern_too_uniform?(timestamps)
    return false if timestamps.length < 2

    # Calculate intervals between consecutive clicks
    intervals = timestamps.each_cons(2).map { |a, b| b - a }

    # Calculate standard deviation of intervals
    std_dev = calculate_std_dev(intervals)

    # If standard deviation is too low, pattern is suspiciously uniform
    # Humans typically have std dev > 50ms
    std_dev < 50
  end

  # Calculate standard deviation of an array
  def calculate_std_dev(array)
    return 0.0 if array.empty?
    return 0.0 if array.length == 1

    mean = array.sum / array.length.to_f
    variance = array.map { |x| (x - mean) ** 2 }.sum / array.length
    Math.sqrt(variance)
  end
end
