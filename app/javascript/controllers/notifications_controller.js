import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button", "list", "content", "loading", "empty", 
                   "allTab", "unreadTab", "mentionsTab"]
  
  connect() {
    this.open = false
    this.currentFilter = "all"
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
    
    // Add event listener for notification clicks
    this.element.addEventListener("click", this.handleNotificationClick.bind(this))
  }
  
  disconnect() {
    this.hide()
    this.element.removeEventListener("click", this.handleNotificationClick.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    this.open ? this.hide() : this.show()
    
    // Remove focus from button after mouse click to prevent focus ring
    // But keep focus for keyboard navigation (Enter/Space key)
    if (this.hasButtonTarget && event.type === 'click' && event.detail > 0) {
      this.buttonTarget.blur()
    }
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
      const response = await fetch('/api/notifications', {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (!response.ok) throw new Error('Failed to fetch notifications')
      
      const data = await response.json()
      
      if (data.notifications && data.notifications.length > 0) {
        // Update the content with fetched notifications
        this.updateNotificationsList(data.notifications)
        this.updateUnreadCount(data.unread_count)
        this.showContent()
      } else {
        this.showEmpty()
      }
    } catch (error) {
      console.error("Failed to load notifications:", error)
      // Fall back to showing existing content if API fails
      if (this.contentTarget.querySelector('[data-notification-id]')) {
        this.showContent()
      } else {
        this.showEmpty()
      }
    }
  }
  
  updateNotificationsList(notifications) {
    // This could be enhanced to dynamically update the DOM
    // For now, the initial render handles it
    console.log(`Loaded ${notifications.length} notifications`)
  }
  
  async markAllRead() {
    try {
      const response = await fetch('/api/notifications/mark_all_as_read', {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      if (!response.ok) throw new Error('Failed to mark all as read')
      
      // Update UI to show all notifications as read
      const unreadNotifications = this.contentTarget.querySelectorAll('[data-notification-unread="true"]')
      
      unreadNotifications.forEach(notification => {
        notification.setAttribute('data-notification-unread', 'false')
        
        // Remove unread indicator
        const indicator = notification.querySelector('.bg-blue-600')
        if (indicator) indicator.remove()
      })
      
      // Update unread count in UI
      this.updateUnreadCount(0)
    } catch (error) {
      console.error("Failed to mark all notifications as read:", error)
    }
  }
  
  showSettings() {
    // Navigate to settings with notifications section
    // The URL is passed as a data attribute based on user type
    const settingsPath = this.element.dataset.settingsPath
    
    if (settingsPath && settingsPath !== '#') {
      window.location.href = `${settingsPath}#notifications`
    } else {
      console.warn('Settings path not available for this user type')
    }
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
    // Don't hide if clicking inside the notification panel or button
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
  
  async handleNotificationClick(event) {
    // Check if we clicked on a notification item
    const notificationEl = event.target.closest('[data-notification-id]')
    if (!notificationEl || !this.contentTarget.contains(notificationEl)) return
    
    const notificationId = notificationEl.dataset.notificationId
    const isUnread = notificationEl.dataset.notificationUnread === 'true'
    
    // If notification is unread, mark it as read
    if (isUnread) {
      try {
        const response = await fetch(`/api/notifications/${notificationId}/mark_as_read`, {
          method: 'PATCH',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          }
        })
        
        if (!response.ok) throw new Error('Failed to mark notification as read')
        
        const data = await response.json()
        
        // Update the notification element to show as read
        notificationEl.setAttribute('data-notification-unread', 'false')
        
        // Remove unread indicator
        const indicator = notificationEl.querySelector('.bg-blue-600')
        if (indicator) indicator.remove()
        
        // Update unread count
        this.updateUnreadCount(data.unread_count)
      } catch (error) {
        console.error("Failed to mark notification as read:", error)
      }
    }
    
    // If notification has a URL, navigate to it
    const linkEl = event.target.closest('a')
    if (linkEl && linkEl.href) {
      // Let the link navigation happen naturally
      this.hide()
    }
  }
}