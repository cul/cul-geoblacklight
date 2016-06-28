# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

# Make the GeoCombine rake tasks available to our app
# So that we can now do, e.g.:
#   bundle exec rake geocombine:clone
#   bundle exec rake geocombine:clone
#   bundle exec rake geocombine:index
# GeoCombine assumes SOLR_URL is found as an ENV variable
ENV['SOLR_URL'] = Blacklight.connection_config[:url]
spec = Gem::Specification.find_by_name 'geo_combine'
load "#{spec.gem_dir}/lib/tasks/geo_combine.rake"


ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.3.zip"
require 'jettywrapper'
