class ApplicationController < ActionController::Base

  # CUL authentication
  include Devise::Controllers::Helpers
  devise_group :user, contains: [:user]
  # before_action :authenticate_user!, if: :devise_controller?


  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

        before_action :allow_geoblacklight_params

        def allow_geoblacklight_params
          # Blacklight::Parameters will pass these to params.permit
          blacklight_config.search_state_fields.append(Settings.GBL_PARAMS)
        end

  private 
  
  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    cas_opts = YAML.load_file(File.join(Rails.root,'config','cas.yml'))[Rails.env] || {}

    # If CAS options are absent, we can only do application-level logout,
    # not CAS logout.  Warn, and proceed.
    unless cas_opts['host'] && cas_opts['logout_url']
      Rails.logger.error "CAS options missing - skipping CAS logout!"
      return request.base_url
    end
    
    # Full CAS logout + application logout page looks like this:
    # https://cas.columbia.edu/cas/logout?service=https://helpdesk.cul.columbia.edu/welcome/logout
    cas_logout_url = 'https://' + cas_opts['host'] + cas_opts['logout_url']
    service = request.base_url
    after_sign_out_path = "#{cas_logout_url}?service=#{service}"
    Rails.logger.debug "after_sign_out_path = #{after_sign_out_path}"
    return after_sign_out_path
  end


end
