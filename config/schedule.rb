# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Give our jobs nice subject lines
set :subject, 'cron output'
set :recipient, 'geodata@library.columbia.edu'
set :job_template, "/usr/local/bin/mailifoutput -s ':subject (:environment)' :recipient /bin/bash -l -c ':job'"

env 'PATH', '/bin:/usr/bin:/home/litoserv/.rvm/wrappers/geoblacklight'

# Rake jobs should use the GeoBlacklight verion of Ruby, not the rvm default
job_type :rake,    "cd /opt/passenger/lito/geoblacklight_dev/current && :environment_variable=:environment ~/.rvm/wrappers/geoblacklight/bundle exec rake :task --silent :output"


# Run on every host - dev, test, prod
every :day, at: '1am' do
  rake 'metadata:process', subject: 'GeoData metadata:process output'
end



# Examples of per-environment cron commands
# 
# if @environment == "geoblacklight_dev"
#     every :weekday, :at => '10pm' do
#         # rake "foo:bar"
#     end
# end
# 
# if @environment == "geoblacklight_test"
#     every :weekend, :at => '0:0am' do
#         # rake "arf:meow"
#     end
# end

