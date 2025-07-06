# Create test notifications for different users
puts "Creating test notifications..."

# Clear existing notifications for a clean slate
puts "Clearing existing notifications..."
Noticed::Notification.destroy_all
Noticed::Event.destroy_all

# Find different types of users
super_admin = User.find_by(system_role: "super_admin")
site_admin = User.find_by(system_role: "site_admin")
direct_users = User.direct.active.limit(3)
team_admins = User.invited.where(team_role: "admin").limit(2)
team_members = User.invited.where(team_role: "member").limit(3)

# Create notifications for different user types
all_users = [ super_admin, site_admin, direct_users, team_admins, team_members ].flatten.compact

if all_users.any?
  all_users.each_with_index do |user, index|
    next unless user

    # Mix of read and unread notifications
    days_ago = rand(0..30)

    # 1. Status change notification (older ones marked as read)
    notification = UserStatusNotifier.with(
      user: user,
      old_status: "inactive",
      new_status: "active",
      changed_by: super_admin || User.first
    ).deliver(user)

    if days_ago > 7
      user.notifications.last&.mark_as_read!
    end

    # 2. Login notification from different locations
    locations = [ "New York, NY", "London, UK", "Tokyo, Japan", "Sydney, Australia", "Berlin, Germany" ]
    ip_addresses = [ "192.168.1.1", "10.0.0.1", "172.16.0.1", "203.0.113.0", "198.51.100.0" ]

    LoginNotifier.with(
      ip_address: ip_addresses.sample,
      user_agent: "Mozilla/5.0 (#{[ 'Macintosh', 'Windows', 'Linux' ].sample})",
      location: locations.sample
    ).deliver(user)

    # 3. Security alerts (critical - always unread)
    if index % 3 == 0
      SecurityAlertNotifier.with(
        alert_type: [ "suspicious_login", "password_reset_attempt", "failed_login_attempts" ].sample,
        ip_address: "185.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
        location: "Unknown Location",
        details: "Multiple failed login attempts detected from this IP address"
      ).deliver(user)
    end

    # 4. Team-specific notifications
    if user.invited? && user.team
      # Team member changes
      TeamMemberNotifier.with(
        team: user.team,
        member: user,
        action: [ "added", "removed", "role_changed" ].sample,
        performed_by: user.team.admin
      ).deliver(user)

      # Mark some as read
      if rand > 0.5
        user.notifications.last&.mark_as_read!
      end

      # Role changes for admins
      if user.team_admin? && index % 2 == 0
        RoleChangeNotifier.with(
          user: user,
          old_role: "member",
          new_role: "admin",
          resource_type: "Team",
          resource_name: user.team.name,
          changed_by: super_admin || user.team.admin
        ).deliver(user)
      end
    end

    # 5. Account updates with various changes
    possible_changes = [
      { first_name: [ "Old First", user.first_name ] },
      { last_name: [ "Old Last", user.last_name ] },
      { phone_number: [ "+1-555-0100", "+1-555-0200" ] },
      { timezone: [ "America/New_York", "America/Los_Angeles" ] },
      { profile_visibility: [ "public", "private" ] }
    ]

    AccountUpdateNotifier.with(
      changes: possible_changes.sample(rand(1..3)).reduce(&:merge)
    ).deliver(user)

    # 6. Admin actions (for some users)
    if index % 4 == 0
      AdminActionNotifier.with(
        action: [ "password_reset", "account_unlocked", "email_verified", "profile_updated" ].sample,
        admin: super_admin || site_admin || User.first,
        details: "Action performed by administrator for security reasons",
        ip_address: "10.0.0.1"
      ).deliver(user)
    end

    # 7. Email change requests (for direct users)
    if user.direct? && index % 3 == 0
      EmailChangeRequestNotifier.with(
        action: [ "submitted", "approved", "rejected" ].sample,
        old_email: user.email,
        new_email: "newemail#{index}@example.com",
        requested_by: user,
        approved_by: super_admin
      ).deliver(user)
    end

    # 8. Invitations sent (for team admins)
    if user.team_admin? && user.team
      emails = [ "newmember1@example.com", "newmember2@example.com", "contractor@example.com" ]

      TeamInvitationNotifier.with(
        team: user.team,
        invitee_email: emails.sample,
        role: [ "member", "admin" ].sample,
        invited_by: user,
        expires_at: 7.days.from_now
      ).deliver(user)

      # Mark older invitations as read
      if days_ago > 3
        user.notifications.last&.mark_as_read!
      end
    end
  end

  # Create some bulk notifications for testing pagination
  if direct_users.any?
    20.times do |i|
      user = direct_users.sample
      next unless user

      AccountUpdateNotifier.with(
        changes: {
          bio: [ "Old bio #{i}", "New bio #{i}" ],
          updated_at: [ (i + 1).days.ago, i.days.ago ]
        }
      ).deliver(user)

      # Mark 70% as read
      if rand > 0.3
        user.notifications.last&.mark_as_read!
      end
    end
  end

  # Create notification events without recipients (system-wide notifications)
  5.times do |i|
    event = SystemAnnouncementNotifier.with(
      title: "System Maintenance #{i + 1}",
      message: "Scheduled maintenance on #{(i + 1).days.from_now.strftime('%B %d, %Y')}",
      priority: [ "low", "medium", "high", "critical" ].sample,
      announcement_type: [ "maintenance", "feature", "security", "general" ].sample
    ).record

    # Deliver to all active users
    User.active.limit(10).each do |user|
      event.deliver(user)
    end
  end

  puts "\n=== Notification Summary ==="
  puts "Total notification events: #{Noticed::Event.count}"
  puts "Total notifications: #{Noticed::Notification.count}"
  puts "Unread notifications: #{Noticed::Notification.unread.count}"
  puts "Read notifications: #{Noticed::Notification.read.count}"

  # Show breakdown by user type
  puts "\nNotifications by user type:"
  puts "- Super Admin: #{super_admin&.notifications&.count || 0}"
  puts "- Site Admin: #{site_admin&.notifications&.count || 0}"
  puts "- Direct Users: #{User.direct.joins(:notifications).distinct.count} users with notifications"
  puts "- Team Admins: #{User.invited.where(team_role: 'admin').joins(:notifications).distinct.count} users with notifications"
  puts "- Team Members: #{User.invited.where(team_role: 'member').joins(:notifications).distinct.count} users with notifications"

  # Show breakdown by notification type
  puts "\nNotifications by type:"
  Noticed::Event.group(:type).count.each do |type, count|
    puts "- #{type.gsub('Notifier', '')}: #{count}"
  end
else
  puts "No active users found. Please create some users first."
end
