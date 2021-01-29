require 'active_hash'

module Plutolib
  module ActiveHashMethods
    def self.included(base)
      static_methods = []
      instance_methods = []
      cmethod_values = {}
      base.data.each do |config|
        if (cname = config[:name]) and (cid = config[:id])
          cmethod = (config[:cmethod] || cname.split(/[ -\/:]/).select(&:present?).join('_')).to_s.downcase.to_sym
          cmethod_values[cid] = cmethod
          next if [:all].include?(cmethod)
          firstchar = cmethod.to_s[0..0]
          next if (firstchar >= '0') and (firstchar <= '9')
          static_methods.push << <<-RUBY
          def #{cmethod}
            @#{cmethod} ||= find(#{cid})
          end
          RUBY
          instance_methods.push <<-RUBY
          def #{cmethod}?
            self.id == #{cid}
          end
          RUBY
        end
      end
      ruby = <<-RUBY
      class << self
        #{static_methods.join("\n")}
      end
      #{instance_methods.join("\n")}
      define_getter_method(:cmethod, nil)
      define_setter_method(:cmethod)
      def to_s
        name
      end

      def self.to_object(thing)
        if thing.nil?
          nil
        elsif thing.is_a?(self)
          thing
        elsif thing.is_a?(Symbol)
          self.send(thing)
        elsif thing.is_a?(String)
          if thing.to_i.to_s == thing
            find(thing)
          else
            find_by_alias(thing)
          end
        elsif thing.is_a?(Integer)
          find(thing)
        elsif thing.is_a?(Enumerable)
          thing.map { |t| to_object(t) }
        else
          nil
        end
      end

      def self.to_ids(*things)
        to_objects(*things).map(&:id)
      end

      def self.to_objects(*things)
        things.flatten.map { |s| to_object(s) }.compact
      end

      def self.to_id(thing)
        to_object(thing).try(:id)
      end

      def ==(rhs)
        if rhs.is_a?(self.class)
          self.name == rhs.name
        elsif rhs.is_a?(String)
          self.name == rhs
        elsif rhs.is_a?(Symbol)
          self.cmethod == rhs
        end
      end

      def self.find_by_alias(find_me)
        all.find do |t|
          t.alias_equals?(find_me)
        end
      end

      def alias_equals?(find_me)
        find_me = find_me.to_s.downcase
        if @all_aliases.nil?
          @all_aliases = [self.name]
          if self.attributes.member?(:aliases)
            @all_aliases = @all_aliases.concat(self.aliases || [])
          end
          @all_aliases = @all_aliases.map(&:downcase)
        end
        @all_aliases.any? { |a| a == find_me }
      end


      RUBY
      # puts "evaluating:\n #{ruby}"
      base.class_eval ruby
      cmethod_values.each do |id, cmethod|
        base.find(id).cmethod = cmethod
      end
    end
  end
end