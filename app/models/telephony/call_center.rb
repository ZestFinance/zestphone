require 'yaml'

module Telephony
  class CallCenter
    attr_reader :name, :host, :username, :password

    def self.load rails_env, config_path = 'config/call_centers.yml'
      @config ||= YAML.load_file(config_path)[rails_env]
    end

    def self.all
      @config.map { |entry| new entry }
    end

    def self.find_by_name name
      all.detect { |call_center| call_center.name == name }
    end

    def initialize opts
      @name = opts['name']
      @host = opts['host']
      @username = opts['username']
      @password = opts['password']
    end
  end
end
