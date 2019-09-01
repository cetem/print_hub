module Customers::Sessions
  extend ActiveSupport::Concern

  included do
    acts_as_authentic do |c|
      c.log_in_after_create = false
      c.log_in_after_password_change = false

      c.crypto_provider = Authlogic::CryptoProviders::BCrypt
      c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    end

    attr_accessor :password_confirmation

    validates :email,
      format: {
        with:    EMAIL_REGEX,
        message: proc { I18n.t('authlogic.error_messages.email_invalid') }
      },
      uniqueness: { case_sensitive: false, if: :will_save_change_to_email? },
      length: { in: 8..255, if: ->(c) { c.email.present? } }
  end
end
