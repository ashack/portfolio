class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # Associate visits with users when they're logged in
    # Check if controller exists and responds to current_user
    if controller && controller.respond_to?(:current_user) && controller.current_user
      data[:user_id] = controller.current_user.id
    end
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
