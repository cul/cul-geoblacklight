
# server 'geoblacklight-prod.cul.columbia.edu', user: 'litoserv', roles: %w{app db web}
# set :deploy_to, '/opt/passenger/lito/geoblacklight_prod'

server 'lito-rails-prod1.cul.columbia.edu', user: 'litoserv', roles: %w{app db web}
set :deploy_to, '/opt/passenger/geoblacklight_prod'
set :rvm_ruby_version, 'geoblacklight_prod'
