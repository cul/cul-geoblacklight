source 'https://rubygems.org'

gem 'rails', '~> 5.0'

# # # Use SCSS for stylesheets
# gem 'sass-rails', '~> 5.0'
# # sass-rails is deprecated, move to sassc-rails
# # But... doesn't build with our servers' gcc 4.4.7
# # gem 'sassc-rails'

# AlmaLinux
gem 'sassc-rails'

gem 'nokogiri'

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
gem 'jbuilder'

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

  gem 'capistrano', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-passenger', require: false
end

gem 'blacklight'

# DEBUG locally
# gem 'geoblacklight', path: "/Users/marquis/src/geoblacklight"
gem 'geoblacklight', '~> 1.0'

gem 'blacklight_range_limit'

# ssh used during rake tasks
gem 'net-ssh'

gem 'rsolr'

# We don't use a local jetty/solr
# gem 'jettywrapper'

# Authentication
gem 'devise'

# gem 'cul_omniauth'
# gem 'cul_omniauth', github: "cul/cul_omniauth", branch: 'rails-5'
gem 'cul_omniauth', git: 'https://github.com/cul/cul_omniauth', branch: 'cas-5.3'

# necessary to quiet a cul_omniauth exception
gem 'rspec'

# Access to GeoCombine tools within our CUL GeoBlacklight app
gem 'geo_combine'

# server deployments use mysql backend db
# UNIX-7336 - Inconsistent MySQL Client Versions
gem 'mysql2'

# To fetch Columbia directory information
gem 'net-ldap'

# Crontab management
gem 'whenever'

# Rails 5 requirement
gem 'listen'

# pin SASS - CUL linux hosts can't yet compile sassc
gem 'bootstrap-sass'

# # Javascript runtime, as a gem, doesn't depend on OS environment
# gem 'therubyracer'

