
# server 'geoblacklight-test.cul.columbia.edu', user: 'litoserv', roles: %w{app db web}
# set :deploy_to, '/opt/passenger/lito/geoblacklight_test'

server 'lito-rails-test1.cul.columbia.edu', user: 'litoserv', roles: %w{app db web}
set :deploy_to, '/opt/passenger/geoblacklight_test'
set :rvm_ruby_version, 'geoblacklight_alma'
