class User < ActiveRecord::Base
  #include Trimmer

  #trimmed_fields :username, :email, :name, :last_name

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Restricciones
  validates :name, :last_name, :language, :presence => true
  validates :name, :last_name, :length => { :maximum => 100 },
    :allow_nil => true, :allow_blank => true
  validates :language, :length => { :maximum => 10 }, :allow_nil => true,
    :allow_blank => true
end