# Rails: Add this to application.rb:
# require 'plutolib/app_config'
# AppConfig = Plutolib::AppConfig.new
module Plutolib
  class AppConfig
    def initialize
      config_file = [ File.join(M2mhub::Engine.root, 'config', 'main_config.yml'),
                      File.join(Rails.root, 'config', 'main_config.yml') ].detect { |p| File.exist?(p) }
      if config_file
        @yaml_config = YAML::load(ERB.new(IO.read(config_file)).result)
      else
        @yaml_config = {}
      end
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

    # Check environment-specific setting first.  Then check shared setting.
    def get(key)
      key = key.to_s
      %w(local_config app_config m2mhub_config).each do |config_key|
        if (config = @yaml_config[config_key])
          if config_key == 'app_config'
            next unless config = config[Rails.env.downcase]
          end
          if config.member?(key)
            return config[key]
          end
        end
      end
      nil
    end
  end
end
