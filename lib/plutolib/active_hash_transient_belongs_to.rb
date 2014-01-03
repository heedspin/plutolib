module Plutolib
  module ActiveHashTransientBelongsTo
    def self.included(base)
      class << base
        def active_hash_transient_belongs_to(attribute_name, args=nil)
          args ||= {}
          class_name = args[:class_name] || attribute_name.to_s.classify
          attribute_id = "#{attribute_name}_id"
          self.class_eval <<-RUBY
          attr_accessor :#{attribute_id} unless method_defined?(:#{attribute_id})
          def #{attribute_name}
            @#{attribute_name} ||= #{class_name}.find_by_id(self.#{attribute_id})
          end
          def #{attribute_name}=(val)
            @#{attribute_name} = val
          end 
          RUBY
        end
      end
    end
  end
end