class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  include Cul::Omniauth::Callbacks

  def affiliations(user, affils)
    user.affils = affils.sort
  end

end
