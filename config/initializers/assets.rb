# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add node_modules to asset load paths if it exists
Rails.application.config.assets.paths << Rails.root.join("node_modules") if Rails.root.join("node_modules").exist?

# Include the Tailwind CSS build directory
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")

# Configure Propshaft compilers for JavaScript modules
Rails.application.config.assets.compilers << [
  "application/javascript",
  Propshaft::Compiler::SourceMappingUrls
]
