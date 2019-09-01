module Users::Sessions
  extend ActiveSupport::Concern

  included do
    acts_as_authentic do |c|
      c.log_in_after_create = false
      c.log_in_after_password_change = false
      c.crypto_provider = Authlogic::CryptoProviders::BCrypt
      c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    end

    attr_accessor :password_confirmation

    validates :username,
      presence:   true,
      format:     {
        with:    /\A[a-zA-Z0-9_][a-zA-Z0-9\.+\-_@ ]+\z/.freeze,
        message: proc {I18n.t('authlogic.error_messages.login_invalid')}
      },
      uniqueness: { case_sensitive: false, if: :will_save_change_to_username? },
      length:     { minimum: 3, maximum: 100, if: ->(c) { c.username.present? } }

    validates :email,
      format: {
        with:    EMAIL_REGEX,
        message: proc { I18n.t('authlogic.error_messages.email_invalid') }
      },
      uniqueness: { case_sensitive: false, if: :will_save_change_to_email? },
      length: { maximum: 100, if: ->(c) { c.email.present? } }

    validates :password,
      confirmation: { if: :require_password? },
      length: { minimum: 8, if: :require_password? }

    validates :password_confirmation,
      length: { minimum: 8, if: :require_password? }
  end
end
