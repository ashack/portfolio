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

    [ status, headers, response ]
  end
end
