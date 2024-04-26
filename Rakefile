# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

# Columbia - Access to APP_CONFIG hash of per-environment settings
require File.join(Rails.root.to_s, 'config', 'initializers/aaa_load_app_config.rb')

Rails.application.load_tasks

# Why?  To support embedded Solr?  To support testing?
# require 'solr_wrapper/rake_task' unless Rails.env.production?
