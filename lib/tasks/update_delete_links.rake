namespace :app do
  desc "Update all delete links to use Turbo syntax"
  task update_delete_links: :environment do
    require 'fileutils'
    
    view_files = Dir.glob(Rails.root.join('app', 'views', '**', '*.erb'))
    
    updated_count = 0
    
    view_files.each do |file|
      content = File.read(file)
      original_content = content.dup
      
      # Pattern to match link_to with method: :delete
      # This regex handles multi-line link_to statements
      content.gsub!(/link_to\s+(.+?),\s*(.+?),\s*method:\s*:delete,?\s*data:\s*\{\s*confirm:\s*["'](.+?)["']\s*\}/m) do
        link_text = $1
        link_path = $2
        confirm_message = $3
        
        # Reconstruct with Turbo syntax
        %(link_to #{link_text}, #{link_path}, data: { turbo_method: :delete, turbo_confirm: "#{confirm_message}" })
      end
      
      # Also handle cases where method: :delete is on its own line
      content.gsub!(/method:\s*:delete,/) do
        'data: { turbo_method: :delete },'
      end
      
      # Handle data: { confirm: "..." } on separate lines
      content.gsub!(/data:\s*\{\s*confirm:\s*["'](.+?)["']\s*\}/) do
        confirm_message = $1
        %(data: { turbo_confirm: "#{confirm_message}" })
      end
      
      if content != original_content
        File.write(file, content)
        updated_count += 1
        puts "Updated: #{file}"
      end
    end
    
    puts "\nTotal files updated: #{updated_count}"
  end
end