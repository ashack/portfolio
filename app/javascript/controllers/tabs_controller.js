import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { 
    defaultTab: String,
    rememberSelected: { type: Boolean, default: false }
  }

  connect() {
    // Check URL hash first
    const hash = window.location.hash.substring(1)
    if (hash && this.hasTabWithParam(hash)) {
      this.showTab(hash)
      return
    }
    
    // Show default tab or remembered tab
    if (this.rememberSelectedValue) {
      const remembered = this.getRememberedTab()
      if (remembered) {
        this.showTab(remembered)
        return
      }
    }

    if (this.defaultTabValue) {
      this.showTab(this.defaultTabValue)
    } else if (this.hasTabTarget) {
      // Show first tab by default
      this.showTab(this.tabTargets[0].dataset.tabsTabParam)
    }
  }

  select(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabsTabParam
    this.showTab(tabId)

    if (this.rememberSelectedValue) {
      this.rememberTab(tabId)
    }
  }

  showTab(tabId) {
    // Update tab states
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabsTabParam === tabId
      tab.classList.toggle("border-indigo-500", isActive)
      tab.classList.toggle("text-indigo-600", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-gray-500", !isActive)
      
      // Update count badges
      const badge = tab.querySelector("span")
      if (badge) {
        badge.classList.toggle("bg-indigo-100", isActive)
        badge.classList.toggle("text-indigo-600", isActive)
        badge.classList.toggle("bg-gray-100", !isActive)
        badge.classList.toggle("text-gray-900", !isActive)
      }
    })

    // Update panel visibility
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.tabsPanelParam === tabId
      panel.classList.toggle("hidden", !isActive)
    })
    
    // Update URL hash without scrolling
    history.replaceState(null, null, `#${tabId}`)
  }

  getRememberedTab() {
    const key = `tabs_${this.element.dataset.tabsIdParam || window.location.pathname}`
    return localStorage.getItem(key)
  }

  rememberTab(tabId) {
    const key = `tabs_${this.element.dataset.tabsIdParam || window.location.pathname}`
    localStorage.setItem(key, tabId)
  }
  
  hasTabWithParam(param) {
    return this.tabTargets.some(tab => tab.dataset.tabsTabParam === param)
  }
}