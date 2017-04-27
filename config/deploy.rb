# config valid only for current version of Capistrano
lock '3.8.1'

set :application, 'geoblacklight'
set :repo_url, 'git@github.com:cul/cul-geoblacklight.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/blacklight.yml', 'config/app_config.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'public/metadata')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp', 'public/metadata')


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# restart passenger with 'touch tmp/restart.txt' instead of 'passenger-config restart-app'
set :passenger_restart_with_touch, true

# Use non-default Ruby
# set :rvm_ruby_string, "2.1.5"
set :rvm_ruby_version, 'geoblacklight'

set :whenever_identifier, ->{ fetch(:stage) }

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
