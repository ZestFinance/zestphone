require 'redis-objects'

Redis.current = Redis.new(:host => 'chubs-staging.rsfqds.0001.use1.cache.amazonaws.com', :port => 6379)
