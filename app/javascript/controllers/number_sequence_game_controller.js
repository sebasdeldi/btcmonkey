import { Controller } from "@hotwired/stimulus"

// Number Sequence Memory Game Controller
// Handles the 5x5 grid game where users click numbers 1-25 in order
export default class extends Controller {
  static targets = [
    "instructions",    // Memorization phase container
    "gameInterface",   // Main game interface (hidden initially)
    "completionScreen", // Completion screen (hidden initially)
    "grid",           // 5x5 number grid container
    "timer",          // Timer display element
    "progress",       // Progress counter (X/25)
    "nextNumber",     // Next number indicator
    "finalTime",      // Final time display
    "finalScore",     // Final score display
    "completionTitle", // Completion title (changes based on rank)
    "rankMessage",    // Rank message
    "leaderboardList", // Leaderboard container
    "exitWarning"     // Exit warning modal
  ]

  static values = {
    gridLayout: Object,       // { "1": [0, 0], "2": [1, 3], ... }
    gameRunUrl: String,       // URL for form submission
    currentUsername: String,  // Current user's username
    leaderboard: Array        // Current top 5 leaderboard
  }

  connect() {
    this.currentNumber = 1
    this.clickSequence = []
    this.clickTimestamps = []
    this.startTime = null
    this.timerInterval = null
    this.gameStarted = false
    this.gameCompleted = false
    this.timerPaused = false
    this.pausedTime = null

    // Check if this game was abandoned (user refreshed/left previously)
    this.checkForAbandonment()

    // Bind event handlers for detecting navigation attempts
    this.handleBeforeUnload = this.onBeforeUnload.bind(this)
    this.handleKeyDown = this.onKeyDown.bind(this)
    this.handlePopState = this.onPopState.bind(this)
    this.handleTurboBeforeVisit = this.onTurboBeforeVisit.bind(this)

    window.addEventListener('beforeunload', this.handleBeforeUnload)
    window.addEventListener('keydown', this.handleKeyDown)
    window.addEventListener('popstate', this.handlePopState)
    // Turbo-specific: intercept Turbo Drive navigation
    document.addEventListener('turbo:before-visit', this.handleTurboBeforeVisit)

    // Add a history state to detect back button
    window.history.pushState({ gamePage: true }, '', window.location.href)

    this.showMemorizationPhase()
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
    window.removeEventListener('beforeunload', this.handleBeforeUnload)
    window.removeEventListener('keydown', this.handleKeyDown)
    window.removeEventListener('popstate', this.handlePopState)
    document.removeEventListener('turbo:before-visit', this.handleTurboBeforeVisit)
  }

  // Check if game was previously abandoned
  checkForAbandonment() {
    const gameRunId = this.gameRunUrlValue.split('/').pop()
    const abandonmentKey = `game_run_${gameRunId}_in_progress`

    if (localStorage.getItem(abandonmentKey) === 'true') {
      // User previously left this game in progress - auto-forfeit
      localStorage.removeItem(abandonmentKey)
      this.autoForfeitAbandoned()
    }
  }

  // Auto-forfeit a game that was abandoned
  autoForfeitAbandoned() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(`${this.gameRunUrlValue}/forfeit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      }
    })
    .then(() => {
      // Redirect to My Games with a message
      window.location.href = '/game_sessions/my_games?forfeited=true'
    })
    .catch(error => {
      console.error('Auto-forfeit error:', error)
      window.location.href = '/game_sessions/my_games'
    })
  }

  // Handle browser refresh/close/navigation - show browser's native warning
  // This only fires for: browser refresh button, typing URL in address bar, closing tab
  // All other navigation (clicking links) is handled by onTurboBeforeVisit
  onBeforeUnload(event) {
    // Only show warning if game has started but not completed
    if (this.gameStarted && !this.gameCompleted) {
      // Mark game as in-progress in localStorage for auto-forfeit on page reload
      const gameRunId = this.gameRunUrlValue.split('/').pop()
      localStorage.setItem(`game_run_${gameRunId}_in_progress`, 'true')

      // This will trigger the browser's native "Leave site?" dialog
      // Note: Modern browsers don't allow custom messages, but the event still prevents navigation
      event.preventDefault()
      event.returnValue = 'Game in progress. If you leave, your game will be forfeited.'
      return 'Game in progress. If you leave, your game will be forfeited.'
    }
  }

  // Handle keyboard shortcuts that might cause navigation
  onKeyDown(event) {
    if (this.gameStarted && !this.gameCompleted) {
      // Detect refresh attempts (Ctrl+R, Cmd+R, F5)
      if ((event.ctrlKey || event.metaKey) && event.key === 'r') {
        event.preventDefault()
        this.pauseTimer()
        this.showExitWarning()
      }
      // Detect F5
      if (event.key === 'F5') {
        event.preventDefault()
        this.pauseTimer()
        this.showExitWarning()
      }
    }
  }

  // Handle back button
  onPopState() {
    if (this.gameStarted && !this.gameCompleted) {
      // Push state again to keep them on the page
      window.history.pushState({ gamePage: true }, '', window.location.href)

      // Show warning modal
      this.pauseTimer()
      this.showExitWarning()
    }
  }

  // Handle Turbo Drive navigation (Rails 8 default for link clicks)
  // This catches: clicking links (logout, navigation, etc.), form submissions
  onTurboBeforeVisit(event) {
    if (this.gameStarted && !this.gameCompleted) {
      // Prevent Turbo navigation entirely
      event.preventDefault()

      // Pause timer and show custom warning modal
      this.pauseTimer()
      this.showExitWarning()
    }
  }

  // Pause the game timer
  pauseTimer() {
    if (this.timerInterval && !this.timerPaused) {
      clearInterval(this.timerInterval)
      this.pausedTime = performance.now() - this.startTime
      this.timerPaused = true
    }
  }

  // Resume the game timer
  resumeTimer() {
    if (this.timerPaused) {
      this.startTime = performance.now() - this.pausedTime
      this.startTimer()
      this.timerPaused = false
    }
  }

  // Show exit warning modal
  showExitWarning() {
    this.exitWarningTarget.style.display = 'flex'
  }

  // Hide exit warning modal
  hideExitWarning() {
    this.exitWarningTarget.style.display = 'none'
  }

  // Handle cancel button - resume game
  cancelExit() {
    this.hideExitWarning()
    this.resumeTimer()
  }

  // Handle exit button - forfeit game
  forfeitGame() {
    this.gameCompleted = true // Prevent beforeunload from triggering again

    // Clear abandonment flag since user is explicitly forfeiting
    const gameRunId = this.gameRunUrlValue.split('/').pop()
    localStorage.removeItem(`game_run_${gameRunId}_in_progress`)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Send forfeit request
    fetch(`${this.gameRunUrlValue}/forfeit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (response.ok) {
        // Successful forfeit - redirect to My Games
        window.location.href = '/game_sessions/my_games'
      } else {
        // Error - still redirect but user will see flash message
        window.location.href = '/game_sessions/my_games'
      }
    })
    .catch(error => {
      console.error('Forfeit error:', error)
      // On error, still redirect to My Games
      window.location.href = '/game_sessions/my_games'
    })
  }

  // Phase 1: Show sequence instructions for 3 seconds
  showMemorizationPhase() {
    let countdown = 3
    const countdownEl = this.element.querySelector('.countdown-timer')

    const countdownInterval = setInterval(() => {
      countdown--
      if (countdownEl) countdownEl.textContent = countdown

      if (countdown <= 0) {
        clearInterval(countdownInterval)
        this.startGame()
      }
    }, 1000)
  }

  // Phase 2: Start the game
  startGame() {
    // Hide instructions, show game interface
    this.instructionsTarget.style.display = 'none'
    this.gameInterfaceTarget.style.display = 'block'

    // Mark game as started
    this.gameStarted = true

    // Render grid with numbers
    this.renderGrid()

    // Start timer
    this.startTime = performance.now()
    this.startTimer()
  }

  // Render 5x5 grid with numbers in random positions
  renderGrid() {
    const gridLayout = this.gridLayoutValue
    const grid = this.gridTarget

    // Create 25 cells (5x5 grid managed by CSS)
    for (let row = 0; row < 5; row++) {
      for (let col = 0; col < 5; col++) {
        // Find which number goes in this position
        const number = this.findNumberAtPosition(row, col, gridLayout)

        const cell = document.createElement('div')
        cell.className = 'number-cell'
        cell.dataset.number = number
        cell.textContent = number
        cell.addEventListener('click', (e) => this.handleCellClick(e))

        grid.appendChild(cell)
      }
    }
  }

  // Find which number is at a given grid position
  findNumberAtPosition(row, col, layout) {
    for (const [number, position] of Object.entries(layout)) {
      if (position[0] === row && position[1] === col) {
        return parseInt(number)
      }
    }
    return null
  }

  // Handle cell click event
  handleCellClick(event) {
    const cell = event.currentTarget
    const clickedNumber = parseInt(cell.dataset.number)

    // Prevent clicking already-clicked cells
    if (cell.classList.contains('clicked')) return

    const timestamp = performance.now() - this.startTime

    if (clickedNumber === this.currentNumber) {
      this.handleCorrectClick(cell, timestamp)
    } else {
      this.handleIncorrectClick(cell)
    }
  }

  // Handle correct click (number in sequence)
  handleCorrectClick(cell, timestamp) {
    // Visual feedback: green flash and mark as clicked
    cell.classList.add('correct-flash', 'clicked')

    // Record click for server validation
    this.clickSequence.push(this.currentNumber)
    this.clickTimestamps.push(timestamp)

    // Update UI
    this.currentNumber++
    this.updateProgress()

    // Check if game complete (all 25 clicked)
    if (this.currentNumber > 25) {
      this.completeGame()
    }
  }

  // Handle incorrect click (wrong number)
  handleIncorrectClick(cell) {
    // Visual feedback: red flash + shake animation
    cell.classList.add('incorrect-flash')

    // Remove animation class after it completes
    setTimeout(() => {
      cell.classList.remove('incorrect-flash')
    }, 500)
  }

  // Update progress display
  updateProgress() {
    this.progressTarget.textContent = `${this.currentNumber - 1}/25`
    this.nextNumberTarget.textContent = this.currentNumber <= 25 ? this.currentNumber : '-'
  }

  // Start and update timer display
  startTimer() {
    this.timerInterval = setInterval(() => {
      const elapsed = (performance.now() - this.startTime) / 1000
      this.timerTarget.textContent = `${elapsed.toFixed(1)}s`

      // Check for 10-minute timeout
      if (elapsed > 600) {
        this.timeoutGame()
      }
    }, 100) // Update every 100ms
  }

  // Handle game timeout (>10 minutes)
  timeoutGame() {
    clearInterval(this.timerInterval)
    this.gameCompleted = true // Prevent exit warnings after timeout

    // Clear abandonment flag since game is being submitted
    const gameRunId = this.gameRunUrlValue.split('/').pop()
    localStorage.removeItem(`game_run_${gameRunId}_in_progress`)

    alert('Time limit exceeded (10 minutes). Game will be scored as 1,999,999ms.')

    // Submit with timeout time
    const timeTaken = 600.1 // Just over limit (will be scored as 1,999,999ms by server)
    this.submitScore(timeTaken)
  }

  // Game complete (all 25 numbers clicked)
  completeGame() {
    clearInterval(this.timerInterval)
    this.gameCompleted = true // Mark as completed to prevent exit warning

    // Clear abandonment flag since game is completing normally
    const gameRunId = this.gameRunUrlValue.split('/').pop()
    localStorage.removeItem(`game_run_${gameRunId}_in_progress`)

    const timeTaken = (performance.now() - this.startTime) / 1000

    // Show completion screen with time and score
    this.showCompletionScreen(timeTaken)
  }

  // Show completion screen with time and calculated score
  showCompletionScreen(timeTaken) {
    // Calculate score using same formula as server
    const score = this.calculateScore(timeTaken)

    // Hide game interface
    this.gameInterfaceTarget.style.display = 'none'

    // Show completion screen
    this.completionScreenTarget.style.display = 'block'

    // Update time and score displays
    this.finalTimeTarget.textContent = `${timeTaken.toFixed(1)}s`
    this.finalScoreTarget.textContent = score

    // Update leaderboard with new score
    this.updateLeaderboard(score)

    // Submit score after 3 seconds
    setTimeout(() => {
      this.submitScore(timeTaken)
    }, 3000)
  }

  // Update leaderboard display with new score
  updateLeaderboard(newScore) {
    // Create updated leaderboard with new score
    const currentUser = this.currentUsernameValue
    const leaderboard = [...this.leaderboardValue]

    // Add current score
    leaderboard.push({ username: currentUser, score: newScore })

    // Sort by score (ascending - lower is better)
    leaderboard.sort((a, b) => a.score - b.score)

    // Take top 5
    const top5 = leaderboard.slice(0, 5)

    // Find user's rank
    const userRank = top5.findIndex(entry => entry.username === currentUser && entry.score === newScore) + 1

    // Update title and message based on rank
    if (userRank === 1) {
      this.completionTitleTarget.textContent = '🏆 NEW RECORD!'
      this.completionTitleTarget.style.color = 'var(--color-warning)'
      this.rankMessageTarget.textContent = "You're #1! Amazing performance!"
      this.rankMessageTarget.style.color = 'var(--color-warning)'
      this.rankMessageTarget.style.fontWeight = 'var(--font-weight-bold)'
    } else if (userRank > 0 && userRank <= 5) {
      this.completionTitleTarget.textContent = '🎉 Great Job!'
      this.rankMessageTarget.textContent = `You ranked #${userRank} in the top 5!`
    } else {
      this.completionTitleTarget.textContent = '✅ Complete!'
      this.rankMessageTarget.textContent = "Try again to beat the top scores!"
    }

    // Render leaderboard list
    this.renderLeaderboard(top5, currentUser, newScore)
  }

  // Render the leaderboard list
  renderLeaderboard(top5, currentUser, currentScore) {
    const list = this.leaderboardListTarget
    list.innerHTML = ''

    top5.forEach((entry, index) => {
      const rank = index + 1
      const isCurrentUser = entry.username === currentUser && entry.score === currentScore

      const item = document.createElement('div')
      item.className = `leaderboard-item ${isCurrentUser ? 'current-user' : ''}`

      const rankBadge = document.createElement('span')
      rankBadge.className = 'leaderboard-rank'
      if (rank === 1) rankBadge.textContent = '🥇'
      else if (rank === 2) rankBadge.textContent = '🥈'
      else if (rank === 3) rankBadge.textContent = '🥉'
      else rankBadge.textContent = `#${rank}`

      const username = document.createElement('span')
      username.className = 'leaderboard-username'
      username.textContent = entry.username
      if (isCurrentUser) username.textContent += ' (You)'

      const scoreDisplay = document.createElement('span')
      scoreDisplay.className = 'leaderboard-score'
      scoreDisplay.textContent = `${entry.score}ms`

      item.appendChild(rankBadge)
      item.appendChild(username)
      item.appendChild(scoreDisplay)

      list.appendChild(item)
    })
  }

  // Calculate score client-side (mirrors server logic)
  // Score = time in milliseconds (lower is better)
  calculateScore(timeSeconds) {
    const MAX_VALID_TIME = 600.0
    const timeMs = Math.round(timeSeconds * 1000)

    // Cap at max time if exceeded
    if (timeSeconds > MAX_VALID_TIME) {
      return Math.round(MAX_VALID_TIME * 1000)
    }

    // Return milliseconds as score
    return timeMs
  }

  // Submit score to server via fetch API
  submitScore(timeTaken) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(`${this.gameRunUrlValue}/complete`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        time_taken: timeTaken,
        click_sequence: this.clickSequence,
        click_timestamps: this.clickTimestamps,
        started_at: new Date(Date.now() - (timeTaken * 1000)).toISOString()
      })
    })
    .then(response => {
      if (response.redirected) {
        window.location.href = response.url
      } else if (response.ok) {
        return response.json()
      } else {
        throw new Error('Submission failed')
      }
    })
    .catch(error => {
      console.error('Game submission error:', error)
      alert('Failed to submit score. Please try again.')
    })
  }
}
