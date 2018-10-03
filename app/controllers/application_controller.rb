class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  # layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  # TODO - A pending GeoBlacklight upgrade (2.0) should
  # make this unnecessary.  See "Skip auth token" in:
  #   https://github.com/geoblacklight/geoblacklight/pull/553
  protect_from_forgery with: :null_session


  def layout_name
     "application"
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
