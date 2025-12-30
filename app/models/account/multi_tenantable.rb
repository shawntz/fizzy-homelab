module Account::MultiTenantable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :multi_tenant, default: false
  end

  class_methods do
    def accepting_signups?
      # Homelab modification: Disable new signups to prevent unauthorized account creation
      false
    end
  end
end
