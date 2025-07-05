# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# Ensure JavaScript files are served with correct MIME type
Rack::Mime::MIME_TYPES[".js"] = "text/javascript"
Rack::Mime::MIME_TYPES[".mjs"] = "text/javascript"
