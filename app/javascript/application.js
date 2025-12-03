// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Custom Turbo Stream action to open a window
import { StreamActions } from "@hotwired/turbo"

StreamActions.open_window = function() {
  const url = this.getAttribute("target")
  window.open(url, '_blank')
}
