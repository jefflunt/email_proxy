module EmailProxy
  class << self
    # As of this writing, the expected values for EMAIL_PROXY_PROVIDER is one of:
    # - 'spendgrid' (the default)
    # - 'snailgun'
    #
    # If the ENV variable is not set then 'spendgrid' is the current default
    def provider
      ENV['EMAIL_PROXY_PROVIDER'] || 'spendgrid'
    end
  end
end
