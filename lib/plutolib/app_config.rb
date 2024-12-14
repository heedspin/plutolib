# Rails: Add this to application.rb:
# require 'plutolib/app_config'
# AppConfig = Plutolib::AppConfig.new
module Plutolib
  class AppConfig
    def env_savvy_merge(path)
      config = YAML::load(IO.read(path), aliases: true)
      if config.member?(Rails.env.to_s)
        config = config[Rails.env.to_s]
      end
      @yaml_config.merge!(config)
    end

    def initialize(yaml_config=nil)
      if yaml_config
        @yaml_config = yaml_config
      else
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
    end

    def load_config(path, merge_point=nil)
      loaded_config = YAML::load(IO.read(path), aliases: true)
      sub_config = merge_point.nil? ? @yaml_config : self.subset_hash(@yaml_config, merge_point)
      sub_config.merge!(loaded_config)
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
        set(mid[0,mid.size-1], args.first)
      else
        get(mid)
      end
    end

    def set(key, value)
      @yaml_config[key.to_s] = value
    end

    def get(key)
      @yaml_config[key.to_s]
    end

    private

    def subset_hash(hash, path_array)
      path_array.reduce(hash) do |current, key|
        return nil unless current.is_a?(Hash) && current.key?(key)

        current[key]
      end
    end
  end
end
