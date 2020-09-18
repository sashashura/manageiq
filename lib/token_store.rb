class TokenStore
  @token_caches = {} # Hash of Memory/Dalli Store Caches, Keyed by namespace

  # only used by TokenManager.token_store
  # @return a token store for users
  def self.acquire(namespace, token_ttl)
    @token_caches[namespace] ||= begin
      options = cache_store_options(namespace, token_ttl)
      case ::Settings.server.session_store
      when "sql"
        SqlStore.new(options)
      when "memory"
        require 'active_support/cache/memory_store'
        ActiveSupport::Cache::MemoryStore.new(options)
      when "cache"
        require 'active_support/cache/dalli_store'
        ActiveSupport::Cache::DalliStore.new(MiqMemcached.server_address, options)
      else
        raise "unsupported session store type: #{::Settings.server.session_store}"
      end
    end
  end

  def self.cache_store_options(namespace, token_ttl)
    {
      :namespace  => "MIQ:TOKENS:#{namespace.upcase}",
      :threadsafe => true,
      :expires_in => token_ttl
    }
  end
  private_class_method :cache_store_options
end
