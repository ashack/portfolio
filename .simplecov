# SimpleCov configuration for comprehensive test coverage tracking

require 'simplecov'

SimpleCov.start 'rails' do
  # Enable branch coverage in addition to line coverage
  enable_coverage :branch

  # Track coverage for all groups separately
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Policies", "app/policies"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Notifiers", "app/notifiers"
  add_group "Validators", "app/validators"
  add_group "Concerns", "app/controllers/concerns"
  add_group "Model Concerns", "app/models/concerns"

  # Exclude files from coverage
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/tmp/'
  add_filter '/log/'

  # Exclude specific files that don't need coverage
  add_filter 'app/channels/application_cable/channel.rb'
  add_filter 'app/channels/application_cable/connection.rb'
  add_filter 'app/jobs/application_job.rb'
  add_filter 'app/mailers/application_mailer.rb'
  add_filter 'app/models/application_record.rb'

  # Set minimum coverage goals
  # TODO: Increase these gradually as coverage improves
  # minimum_coverage 80
  # minimum_coverage_by_file 50

  # Configure output formats
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter
  ])

  # Set output directory
  coverage_dir 'coverage'

  # Track files that were not loaded during test run
  track_files '{app,lib}/**/*.rb'

  # Refuse to run tests if coverage data is too old
  # (helps ensure coverage data is fresh)
  # refuse_coverage_drop # Disabled during initial coverage improvement

  # Maximum age of coverage data (in seconds)
  # Default is 600 (10 minutes)
  merge_timeout 600
end

# Configure result merging for parallel tests
SimpleCov.use_merging true
SimpleCov.merge_timeout 3600 # 1 hour for CI environments
