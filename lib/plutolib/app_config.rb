# Rails: Add this to application.rb:
# require 'plutolib/app_config'
# AppConfig = Plutolib::AppConfig.new
module Plutolib
  class AppConfig
    def env_savvy_merge(path)
      config = YAML::load(IO.read(path))
      if config.member?(Rails.env.to_s)
        config = config[Rails.env.to_s]
      end
      @yaml_config.merge!(config)
    end

    def initialize
      @yaml_config = {}
      local_config = nil
      app_config = nil
      Dir.glob(File.join(Rails.root, 'config/app_config/*.y*ml')).each do |path|
        if path.include?('/local_config.y')
          local_config = path
        elsif path.include?('/app_config.y')
          app_config = path
        else
          env_savvy_merge(path)
        end
      end
      env_savvy_merge(app_config) if app_config
      env_savvy_merge(local_config) if local_config
    end

    def method_missing(mid, *args)
      mid = mid.to_s
      if mid =~ /(.+)\?$/
        val = get($1)
        if val.nil?
          return false
        elsif val.is_a?(FalseClass) or val.is_a?(TrueClass)
          return val
        else
          return !['0', 'false', 'nil'].include?(val.downcase)
        end
      elsif mid[mid.size-1, mid.size-1] == '='
        set_local(mid[0,mid.size-1], args.first)
      else
        get(mid)
      end
    end

    def set_local(key, value)
      (@yaml_config['local_config'] ||= {})[key] = value
    end

    def get(key)
      @yaml_config[key.to_s]
    end
  end
end
