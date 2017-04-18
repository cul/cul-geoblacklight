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

# Runs on every host
every :day, at: '2pm' do
  rake 'metadata:download'
end

if @environment == "geoblacklight_dev"
    every :weekday, :at => '10pm' do
        rake "foo:bar"
    end
end

if @environment == "geoblacklight_test"
    every :weekend, :at => '0pm' do
        rake "arf:meow"
    end
end
