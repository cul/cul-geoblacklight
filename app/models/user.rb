class User < ApplicationRecord
  include Cul::Omniauth::Users

  # include Devise::Models::DatabaseAuthenticatable

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User

  # # Include default devise modules. Others available are:
  # # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable

  # # devise :cas_authenticatable, authentication_keys: [:login]
  # devise :cas_authenticatable

  before_validation(:default_email, on: :create)
  before_create :set_personal_info_via_ldap

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def name
    [first_name, last_name].join(' ')
  end

  def login
    self.uid.split('@').first
  end

  def default_email
    if self.login
      self.email = "#{self.login}@columbia.edu"
    end
  end

  # Password methods required by Devise.
  def password
    Devise.friendly_token[0,20]
  end

  def password=(*val)
    # NOOP
  end

  def admin?
    affils && (affils.include?('CUNIX_litosys') || affils.include?('CUL_dpts-dev'))
  end

  def set_personal_info_via_ldap
    if login
      entry = Net::LDAP.new(host: 'ldap.columbia.edu', port: 389).search(base: 'o=Columbia University, c=US', filter: Net::LDAP::Filter.eq('uid', login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          # self.email = wind_login + '@columbia.edu'
          self.email = login + '@columbia.edu'
        end
        if User.column_names.include? 'last_name'
          self.last_name = entry[:sn].to_s.gsub('[', '').gsub(']', '').gsub(/\"/, '')
        end
        if User.column_names.include? 'first_name'
          self.first_name = entry[:givenname].to_s.gsub('[', '').gsub(']', '').gsub(/\"/, '')
        end
      end
    end

    self
  end


end
