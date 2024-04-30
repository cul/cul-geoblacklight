class AdminController < ApplicationController
  # GeoBlacklight version not included automatically
  require 'geoblacklight/version'

  before_action :authenticate_user!

  def system
    redirect_to root_path unless current_user.admin?
  end

end
