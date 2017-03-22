module Plutolib
  module SerializedAttributes
    def self.included(base)
      class << base
        def serialized_attribute(key, args=nil)
          args ||= {}
          storage_column = args[:data] || 'data'
          deserialize = args[:deserialize] || args[:des]
          default = args.member?(:default) ? args[:default] : 0
          unless self.method_defined?(storage_column)
            self.class_eval <<-RUBY
            def #{storage_column}
              if @#{storage_column}.nil?
                if x = super
                  @#{storage_column} = x.is_a?(String) ? ActiveSupport::JSON.decode(x) : x
                else
                  @#{storage_column} = Hash.new(#{default})
                end
              end
              @#{storage_column}
            end        
            before_save :serialize_#{storage_column}
            def serialize_#{storage_column}
              self.#{storage_column} = self.#{storage_column}.to_json
            end
            RUBY
          end
          self.class_eval <<-RUBY
          attr_accessor :#{key}
          def #{key}=(val)
            self.#{storage_column}_will_change! unless self.#{storage_column}['#{key}'] == val
            self.#{storage_column}['#{key}'] = val
          end
          RUBY
          if deserialize
            self.class_eval <<-RUBY
            def #{key}
              self.#{storage_column}['#{key}'].try(:send, '#{deserialize.to_s}')
            end
            RUBY
          else
            self.class_eval <<-RUBY
            def #{key}
              self.#{storage_column}['#{key}']
            end
            RUBY
          end
        end

        def serialized_column(storage_column, args=nil)
          args ||= {}
          default = args.member?(:default) ? args[:default] : 0
          type = args.member?(:type) ? args[:type] : Hash
          self.class_eval <<-RUBY
          def #{storage_column}
            if @#{storage_column}.nil?
              if x = super
                @#{storage_column} = x.is_a?(String) ? ActiveSupport::JSON.decode(x) : x
              else
                @#{storage_column} = #{type}.new(#{default})
              end
            end
            @#{storage_column}
          end
          before_save :serialize_#{storage_column}
          def serialize_#{storage_column}
            self.#{storage_column} = self.#{storage_column}.to_json
          end
          RUBY
        end
      end
    end
  end
end