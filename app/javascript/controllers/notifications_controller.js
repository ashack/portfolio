import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button", "list", "content", "loading", "empty", 
                   "allTab", "unreadTab", "mentionsTab"]
  
  connect() {
    this.open = false
    this.currentFilter = "all"
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }
  
  disconnect() {
    this.hide()
  }
  
  toggle(event) {
    event.stopPropagation()
    this.open ? this.hide() : this.show()
  }
  
  show() {
    if (this.open) return
    
    this.open = true
    this.panelTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    document.addEventListener("click", this.handleClickOutside)
    
    // Load notifications if not already loaded
    this.loadNotifications()
  }
  
  hide() {
    if (!this.open) return
    
    this.open = false
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    
    // Remove event listeners
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("click", this.handleClickOutside)
  }
  
  async loadNotifications() {
    // Show loading state
    this.showLoading()
    
    try {
      // In a real app, you'd fetch notifications from the server
      // For now, just simulate a delay
      await new Promise(resolve => setTimeout(resolve, 500))
      
      // Show content
      this.showContent()
    } catch (error) {
      console.error("Failed to load notifications:", error)
      this.showEmpty()
    }
  }
  
  markAllRead() {
    // Mark all notifications as read
    const unreadNotifications = this.contentTarget.querySelectorAll('[data-notification-unread="true"]')
    
    unreadNotifications.forEach(notification => {
      notification.setAttribute('data-notification-unread', 'false')
      
      // Remove unread indicator
      const indicator = notification.querySelector('.bg-blue-600')
      if (indicator) indicator.remove()
    })
    
    // Update unread count in UI
    this.updateUnreadCount(0)
    
    // In a real app, you'd send this to the server
    console.log("Marked all notifications as read")
  }
  
  showSettings() {
    // Navigate to notification settings
    window.location.href = '/settings/notifications'
  }
  
  filterAll() {
    this.setActiveTab("all")
    this.filterNotifications("all")
  }
  
  filterUnread() {
    this.setActiveTab("unread")
    this.filterNotifications("unread")
  }
  
  filterMentions() {
    this.setActiveTab("mentions")
    this.filterNotifications("mentions")
  }
  
  setActiveTab(filter) {
    // Reset all tabs
    const tabs = [this.allTabTarget, this.unreadTabTarget, this.mentionsTabTarget]
    tabs.forEach(tab => {
      tab.classList.remove("bg-gray-100", "text-gray-700")
      tab.classList.add("text-gray-500", "hover:text-gray-700", "hover:bg-gray-50")
    })
    
    // Set active tab
    const activeTab = this[`${filter}TabTarget`]
    activeTab.classList.remove("text-gray-500", "hover:text-gray-700", "hover:bg-gray-50")
    activeTab.classList.add("bg-gray-100", "text-gray-700")
    
    this.currentFilter = filter
  }
  
  filterNotifications(filter) {
    const notifications = this.contentTarget.querySelectorAll('[data-notification-id]')
    let hasVisibleNotifications = false
    
    notifications.forEach(notification => {
      let shouldShow = false
      
      switch (filter) {
        case "all":
          shouldShow = true
          break
        case "unread":
          shouldShow = notification.getAttribute('data-notification-unread') === 'true'
          break
        case "mentions":
          // Check if notification contains a mention (simplified check)
          shouldShow = notification.textContent.includes('@')
          break
      }
      
      notification.style.display = shouldShow ? '' : 'none'
      if (shouldShow) hasVisibleNotifications = true
    })
    
    // Show empty state if no notifications match filter
    if (!hasVisibleNotifications) {
      this.showEmpty()
    }
  }
  
  showLoading() {
    this.hideAll()
    this.loadingTarget.classList.remove("hidden")
  }
  
  showContent() {
    this.hideAll()
    this.contentTarget.classList.remove("hidden")
  }
  
  showEmpty() {
    this.hideAll()
    this.emptyTarget.classList.remove("hidden")
  }
  
  hideAll() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.add("hidden")
    if (this.hasContentTarget) this.contentTarget.classList.add("hidden")
    if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")
  }
  
  updateUnreadCount(count) {
    // Update badge in button
    const badge = this.buttonTarget.querySelector('.animate-pulse')
    if (badge) {
      if (count === 0) {
        badge.remove()
      }
    }
    
    // Update count in unread tab
    const unreadBadge = this.unreadTabTarget.querySelector('.bg-red-100')
    if (unreadBadge) {
      if (count === 0) {
        unreadBadge.remove()
      } else {
        unreadBadge.textContent = count
      }
    }
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}