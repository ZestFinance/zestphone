require 'redis-namespace'

redis = Redis.new(:host => 'chubs-staging.rsfqds.0001.use1.cache.amazonaws.com', :port => 6379)
Redis.current = Redis::Namespace.new('staging', :redis => redis)
