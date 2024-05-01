class OmniauthSupport < ActiveRecord::Migration[6.1]

  def change
    # CUL Omniauth needs fiels for provider and uid
    add_column(:users, :provider, :string, default: 'saml')
    add_column(:users, :uid, :string)

    # cul_omniauth includes :trackable - add more fields
     add_column(:users, :sign_in_count, :integer, default: 0, null: false)
     add_column(:users, :current_sign_in_at, :datetime)
     add_column(:users, :last_sign_in_at, :datetime)
     add_column(:users, :current_sign_in_ip, :string)
     add_column(:users, :last_sign_in_ip, :string)

    # Support in case we want to manage authorization using affils
    add_column(:users, :affils, :text)
  end

end
