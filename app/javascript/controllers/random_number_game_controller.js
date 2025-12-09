import { Controller } from "@hotwired/stimulus"

/**
 * Random Number Game Controller
 *
 * Handles the simple random number generator mini-game (0-100).
 *
 * User Flow:
 * 1. User sees "Generate Number" button
 * 2. Clicks button → Animated number cycling begins
 * 3. After ~1 second → Final score displayed
 * 4. User confirms score → Submitted to server
 *
 * Targets:
 * - gameArea: Initial state with play button
 * - resultArea: Result state with score and confirm button
 * - playButton: The "Generate Number" button
 * - scoreDisplay: The animated score number display
 * - scoreInput: Hidden input field for form submission
 * - form: The form that submits the score
 */
export default class extends Controller {
  static targets = [
    "gameArea",
    "resultArea",
    "playButton",
    "scoreDisplay",
    "scoreInput",
    "form"
  ]

  /**
   * Play button click handler.
   *
   * Starts the animated number generation sequence.
   *
   * @param {Event} event - The click event
   */
  play(event) {
    event.preventDefault()

    // Disable button to prevent double-clicks
    this.playButtonTarget.disabled = true
    this.playButtonTarget.textContent = "Generating..."

    // Animate random numbers for dramatic effect
    this.animateRandomNumbers()
  }

  /**
   * Animates random numbers cycling through values.
   *
   * Shows 20 random values over ~1 second (50ms intervals),
   * then displays the final score.
   */
  animateRandomNumbers() {
    let count = 0
    const totalIterations = 20

    const interval = setInterval(() => {
      // Generate random number 0-100
      const randomNum = Math.floor(Math.random() * 101)
      this.scoreDisplayTarget.textContent = randomNum
      count++

      // Stop after 20 iterations
      if (count >= totalIterations) {
        clearInterval(interval)
        this.showResult()
      }
    }, 50) // 50ms = ~1 second total
  }

  /**
   * Shows the final result screen.
   *
   * Generates the final score, updates the UI,
   * transitions from game area to result area,
   * and automatically submits the score.
   */
  showResult() {
    // Generate final score
    const finalScore = Math.floor(Math.random() * 101)

    // Update display and hidden input
    this.scoreDisplayTarget.textContent = finalScore
    this.scoreInputTarget.value = finalScore

    // Transition to result view
    this.gameAreaTarget.classList.add("hidden")
    this.resultAreaTarget.classList.remove("hidden")

    // Auto-submit the form after a brief delay to show the score
    setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 1500) // 1.5 second delay to let user see their score
  }
}
