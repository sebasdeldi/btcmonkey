import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "totalDisplay"]
  static values = {
    pricePerSpot: Number
  }

  connect() {
    this.updateTotal()
  }

  updateTotal() {
    const quantity = parseInt(this.quantityTarget.value) || 1
    const total = quantity * this.pricePerSpotValue
    this.totalDisplayTarget.textContent = `Total: ${total} credits`
  }
}
