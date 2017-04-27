# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Give our jobs nice subject lines
set :email_subject, "cron output"
set :environment, Rails.env
set :job_template, "mailifoutput -s ':email_subject (:environment)' -- /bin/bash -l -c ':job'"


# Run on every host - dev, test, prod
every :monday, at: '1am' do
  rake 'metadata:process', email_subject: 'GeoBL metadata:process'
end

every :thursday, at: '1:15pm' do
  rake 'metadata:process', email_subject: 'GeoBL metadata:process'
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

