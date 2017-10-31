require "rake"
require "ember/schema/version"
require "ember/schema/rest_pack"
require "ember/schema/active_model"
require "ember/schema/jsonapi_resource"

module Ember
  module Schema
    def self.generate(type)
      return unless const_defined?("::#{type.to_s}")

      schema_hash = {}

      case type.to_s
        when "JSONAPI::Resource"
          generator = JsonapiResource.new
        when "RestPack::Serializer"
          generator = RestPack.new
        when "ActiveModel::Serializer"
          generator = ActiveModel.new
        else
          return
      end

      generator.serializers.sort_by(&:name).each do |serializer_class|
        begin
          next if generator.abstract?(serializer_class)

          klass = generator.get_klass(serializer_class)
          if klass.present?
            # if we are dealing with a polymorphic class, then process accordingly
            if klass.respond_to?(:base_class) && klass != klass.base_class
              next
            end

            schema = generator.schema(serializer_class, klass)
            name = generator.camelize(serializer_class, klass)
            schema_hash[name] = schema
            # Check for inherited serializer classes now
            generator.descendants(serializer_class).each do |child_serializer_class|
              begin
                # to be inherited, it has to have a subclass thats not the base and a klass that is inherited
                if generator.abstract?(child_serializer_class) || # skip, default class
                  generator.abstract?(child_serializer_class.superclass) || # skip, base is default class, not inherited
                  child_serializer_class.superclass == generator.superclass || # skip, default class
                  child_serializer_class == serializer_class # skip serializer is itself
                  next
                end
                child_klass = generator.get_klass(child_serializer_class)
                if child_klass.present?
                  # if we are dealing with a polymorphic class, then process accordingly
                  next unless child_klass.respond_to?(:base_class) # this is not active record
                  next if child_klass == child_klass.base_class # this is the base class
                  next unless child_klass.base_class == klass # this is not a subclass of klass
                  diff_schema = inherited_schema(child_serializer_class, child_klass, schema, generator)
                  child_name = child_klass.name.camelize
                  # Modify parents schema
                  schema[:descendants] ||= {}
                  schema[:descendants][child_name] = diff_schema
                end
              rescue => e
                p e
                print e.backtrace.join("\r\n")
              end
            end
          end
        rescue => e
          p e
          print e.backtrace.join("\r\n")
        end
      end

      schema_hash
    end

  private

    def self.inherited_schema(serializer, klass, base_schema, generator)
      schema = generator.schema(serializer, klass)

      schema_diff = {}
      schema_diff[:attributes] = diff(base_schema[:attributes], schema[:attributes])
      schema_diff[:associations] = diff(base_schema[:associations], schema[:associations])
      schema_diff[:defaults] = diff(base_schema[:defaults], schema[:defaults])
      return schema_diff
    end

    def self.diff(base, child)
      diff = {}
      child.each do |key, value|
        if !base.has_key?(key) || (base.has_key?(key) && base[key] != value)
          diff[key] = value
        end
      end
      return diff
    end
  end
end

load "tasks/ember.rake"
