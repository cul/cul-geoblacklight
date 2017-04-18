source 'http://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# We don't need these
# # bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

group :development, :test do
  # We don't use this
  #   # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #   gem 'byebug'

  # Use sqlite3 as the database for Active Record in dev and test
  gem 'sqlite3'
end

group :development do
  # We don't use this
  # # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'

  # We use this instead - errors give an in-browser debugger
  gem 'better_errors'
  gem 'binding_of_caller'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Capistrano deployment
  gem 'capistrano', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', require: false

end


gem 'blacklight'
gem 'geoblacklight'
gem 'blacklight_range_limit'

# ssh used during rake tasks
gem 'net-ssh'

gem 'rsolr'

# We don't use a local jetty/solr
# gem 'jettywrapper'


# Authentication
gem 'devise', '~> 3.0'
gem 'cul_omniauth'
# necessary to quiet a cul_omniauth exception
gem 'rspec'

# Access to GeoCombine tools within our CUL GeoBlacklight app
gem 'geo_combine'

# server deployments use mysql backend db
gem 'mysql2'

# To fetch Columbia directory information
gem 'net-ldap'

# Crontab management
gem 'whenever'
