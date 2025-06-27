import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    this.isOpen = false
  }
  
  toggle() {
    this.isOpen = !this.isOpen
    const sidebar = document.getElementById('sidebar')
    
    if (sidebar) {
      sidebar.classList.toggle('-translate-x-full')
    }
  }
  
  close() {
    this.isOpen = false
    const sidebar = document.getElementById('sidebar')
    
    if (sidebar) {
      sidebar.classList.add('-translate-x-full')
    }
  }
}