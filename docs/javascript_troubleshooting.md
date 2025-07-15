# JavaScript Troubleshooting Guide for Rails 8

## Common JavaScript Issues and Solutions

### 1. MIME Type Errors: "Loading module was blocked because of a disallowed MIME type"

#### Symptoms
- Console errors: `Loading module from "http://localhost:3000/assets/controllers/..." was blocked because of a disallowed MIME type ("text/plain")`
- Stimulus controllers not loading
- JavaScript modules failing to import

#### Root Causes
1. **Incorrect import paths** (most common)
2. Incorrect MIME type configuration
3. Asset pipeline misconfiguration

#### Solution 1: Fix Import Paths (Primary Solution)

The most common cause is using relative imports instead of importmap module specifiers.

**❌ Wrong (relative imports):**
```javascript
// app/javascript/controllers/index.js
import { application } from "./application"
import SomeController from "./some_controller"
```

**✅ Correct (importmap module specifiers):**
```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import SomeController from "controllers/some_controller"
```

**Why this happens:**
- Rails 8 uses importmap-rails with Propshaft
- Relative paths (`./`) bypass the importmap system
- Browser tries to load files directly, resulting in MIME type errors

#### Solution 2: Configure MIME Types

If import paths are correct but errors persist, configure MIME types:

1. **Update `config/initializers/mime_types.rb`:**
```ruby
# Ensure JavaScript files are served with correct MIME type
Rack::Mime::MIME_TYPES[".js"] = "application/javascript"
Rack::Mime::MIME_TYPES[".mjs"] = "application/javascript"
```

2. **Add middleware for JavaScript MIME types:**

Create `app/middleware/javascript_mime_type.rb`:
```ruby
class JavascriptMimeType
  def initialize(app)
    @app = app
  end

  def call(env)
    # Check if this is a JavaScript file request
    if env["PATH_INFO"] =~ /\.(js|mjs)$/ || env["PATH_INFO"] =~ /\/assets\/controllers\//
      # Set proper accept header for the request
      env["HTTP_ACCEPT"] = "application/javascript, */*" if env["HTTP_ACCEPT"].nil? || env["HTTP_ACCEPT"].empty?
    end
    
    status, headers, response = @app.call(env)
    
    # Fix MIME type for JavaScript files in the response
    if env["PATH_INFO"] =~ /\.(js|mjs)$/ || env["PATH_INFO"] =~ /\/assets\/controllers\//
      headers["Content-Type"] = "application/javascript; charset=utf-8"
      headers.delete("X-Content-Type-Options") # Remove if it's causing issues
    end
    
    [status, headers, response]
  end
end
```

Register in `config/application.rb`:
```ruby
# Fix JavaScript MIME type issues (insert early in stack)
require_relative "../app/middleware/javascript_mime_type"
config.middleware.insert_after ActionDispatch::Static, JavascriptMimeType
```

#### Solution 3: Configure Propshaft

In `config/initializers/assets.rb`:
```ruby
# Configure Propshaft compilers for JavaScript modules
Rails.application.config.assets.compilers << [
  'application/javascript', 
  Propshaft::Compiler::SourceMappingUrls
]
```

#### Solution 4: Clear Asset Cache

```bash
# Clear all caches
bin/rails tmp:clear
bin/rails assets:clobber

# Remove manifest if it exists
rm -f public/assets/.manifest.json

# Precompile assets (in development)
RAILS_ENV=development bin/rails assets:precompile

# Remove the manifest again to allow dynamic compilation
rm -f public/assets/.manifest.json

# Restart the server
bin/rails restart
```

### 2. Stimulus Controllers Not Connecting

#### Check Import Map Configuration

Verify `config/importmap.rb`:
```ruby
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
```

#### Verify Controller Registration

Check that controllers are properly imported in `app/javascript/controllers/index.js`:
```javascript
import { application } from "controllers/application"

// Ensure each controller uses the correct import path
import DropdownController from "controllers/dropdown_controller"
application.register("dropdown", DropdownController)
```

### 3. Debugging JavaScript Issues

#### Enable Stimulus Debug Mode

In `app/javascript/controllers/application.js`:
```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = true  // Enable debug mode
window.Stimulus = application

export { application }
```

#### Check Browser Console

1. Open browser developer tools (F12)
2. Check Console tab for errors
3. Check Network tab for failed requests
4. Verify Content-Type headers for .js files

#### Verify MIME Types

```bash
# Check if JavaScript files are served with correct MIME type
curl -I http://localhost:3000/assets/application.js | grep -i content-type
# Should show: content-type: application/javascript

# Check a specific controller
curl -I http://localhost:3000/assets/controllers/dropdown_controller.js | grep -i content-type
# Should show: content-type: application/javascript
```

### 4. Common Pitfalls

1. **Auto-generated files**: The `app/javascript/controllers/index.js` file is auto-generated. If you manually edit it, run:
   ```bash
   bin/rails stimulus:manifest:update
   ```

2. **Turbo and JavaScript conflicts**: Ensure Turbo isn't interfering with your JavaScript:
   ```javascript
   // Disable Turbo for specific elements
   <div data-turbo="false">
     <!-- Your content -->
   </div>
   ```

3. **Propshaft vs Sprockets**: Rails 8 uses Propshaft by default. Don't mix Sprockets configurations.

### 5. Quick Checklist

When JavaScript isn't working:

- [ ] Check browser console for MIME type errors
- [ ] Verify import paths use module specifiers, not relative paths
- [ ] Clear asset cache and restart server
- [ ] Check that `config/importmap.rb` includes your files
- [ ] Verify controllers are registered in `controllers/index.js`
- [ ] Ensure MIME types are configured correctly
- [ ] Check that Stimulus debug mode shows controllers connecting

### 6. Emergency Reset

If nothing else works:

```bash
# Stop the server
# Then run:
bin/rails tmp:clear
bin/rails assets:clobber
rm -rf node_modules
rm -f public/assets/.manifest.json
bundle install
bin/rails stimulus:manifest:update
bin/rails restart
```

## References

- [Rails 8 Asset Pipeline Guide](https://guides.rubyonrails.org/asset_pipeline.html)
- [Importmap Rails Documentation](https://github.com/rails/importmap-rails)
- [Propshaft Documentation](https://github.com/rails/propshaft)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)