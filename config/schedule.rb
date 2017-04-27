# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# # Load rails environment
# require File.expand_path('../config/environment', __dir__)
# 
# # Set environment to current environment.
# set :environment, Rails.env

# Give our jobs nice subject lines
set :subject, "cron output"
set :to, Etc.getpwuid(Process.uid).name
set :job_template, "/usr/local/bin/mailifoutput -s ':subject (@environment)' :to -- /bin/bash -l -c ':job'"


# Run on every host - dev, test, prod
every :monday, at: '1am' do
  rake 'metadata:process', subject: 'GeoBL metadata:process output'
end

every :thursday, at: '4:45pm' do
  rake 'metadata:process', subject: 'GeoBL metadata:process output'
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

