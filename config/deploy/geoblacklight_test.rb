
server 'geoblacklight-test.cul.columbia.edu', user: 'litoserv', roles: %w{app db web}
set :deploy_to, '/opt/passenger/lito/geoblacklight_test'
