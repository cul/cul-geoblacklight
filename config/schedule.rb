# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Run on every host
every(:monday, at: '1am') { rake 'metadata:download' }
every :monday, at: '2am' do rake 'metadata:validate_downloads' end
every :monday, at: '3am' do rake 'metadata:validate_layers' end
every :monday, at: '4am' do rake 'metadata:htmlize' end
every :monday, at: '5am' do rake 'metadata:transform' end
# Not quite to the point of auto-updating
# every :monday, at: '6am' do rake 'metadata:ingest' end


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

