# A huge thanks to Tom Lea for this snippet
# git://gist.github.com/177780.git
#
# Help from http://stackoverflow.com/questions/660599/rails-per-request-hash
#
## Configure it up in config/environment.rb with:
##   config.middleware.use PerRequestCache
## then use it with:
##   PerRequestCache.fetch(:foo_cache){ some_expensive_foo }
#
class PerRequestCache #THIS IS TOTALLY NOT THREAD SAFE!!!!!!!

  class << self
    def open_the_cache
      @cache = {}
    end

    def clear_the_cache
      @cache = nil
    end

    def fetch(key, &block)
      return yield if @cache.nil?
      @cache[key] ||= yield
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    self.class.open_the_cache
    @app.call(env)
  ensure
    self.class.clear_the_cache
  end
end