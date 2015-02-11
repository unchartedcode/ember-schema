require "rake"
require "ember/schema/version"

load "lib/tasks/ember"

module Ember
  module Schema
    def self.generate
      schema_hash = {}
      # Rails.application.eager_load! # populate descendants

      RestPack::Serializer.class_map.sort_by { |s| s[0] }.map { |s| s[1] }.each do |serializer_class|
        begin
          next if serializer_class == ApplicationSerializer
          next if serializer_class.respond_to?(:ignore) && serializer_class.ignore
          klass = get_klass(serializer_class)
          if klass.present?
            # if we are dealing with a polymorphic class, then process accordingly
            if klass.respond_to?(:base_class) && klass != klass.base_class
              p "--Skipping inherited class: '#{klass.name}', it will be processed with parent"
              next
            end
            schema = schema(serializer_class, klass)
            name = klass.name.camelize
            schema_hash[name] = schema
            p "#{klass.name}: Complete"
            # Check for inherited serializer classes now
            serializer_class.descendants.sort_by { |s| s.name }.each do |child_serializer_class|
              begin
                # to be inherited, it has to have a subclass thats not the base and a klass that is inherited
                if child_serializer_class == ApplicationSerializer || # skip, default class
                  child_serializer_class.superclass == ApplicationSerializer || # skip, base is default class, not inherited
                  child_serializer_class.superclass == RestPack::Serializer || # skip, default class
                  child_serializer_class == serializer_class # skip serializer is itself
                  next
                end
                child_klass = get_klass(child_serializer_class)
                if child_klass.present?
                  # if we are dealing with a polymorphic class, then process accordingly
                  next unless child_klass.respond_to?(:base_class) # this is not active record
                  next if child_klass == child_klass.base_class # this is the base class
                  next unless child_klass.base_class == klass # this is not a subclass of klass
                  diff_schema = inherited_schema(child_serializer_class, child_klass, schema)
                  child_name = child_klass.name.camelize
                  # Modify parents schema
                  schema[:descendants] ||= {}
                  schema[:descendants][child_name] = diff_schema
                  p "  > #{child_klass.name}: Child Complete"
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

    def self.get_klass(serializer)
      return serializer.model_class
      # module_name = serializer.name.deconstantize
      # class_name = serializer.root_name.camelize
      # full_name = [module_name, class_name].reject(&:empty?).join("::")
      # begin
      #   return full_name.constantize
      # rescue => e
      #   p " - Unable to find model: '#{full_name}'. Skipping schema processing."
      #   return nil
      # end
    end

    def self.schema(serializer, klass)
      columns = if klass.respond_to? :columns_hash then klass.columns_hash else {} end

      attrs = {}
      (serializer.serializable_attributes || {}).each do |id, name|
        options = serializer.serializable_attributes_options[id] || {}
        if options[:type].present?
          attrs[name] = options[:type].to_s
        else
          # If no type is given, attempt to get it from the Active Model class
          if column = columns[name.to_s]
            attrs[name] = column.type
          else
            # Other wise default to string
            attrs[name] = "string"
          end
        end
      end

      associations = {}

      serializer.can_include.each do |association_name|
        #association = association_class.new(attr, self)

        if model_association = klass.reflect_on_association(association_name)
          # Real association.
          associations[association_name] = { model_association.macro => model_association.class_name.pluralize.underscore.downcase }
        # elsif model_association = get_type(association)
        #   # Computed association. We could infer has_many vs. has_one from
        #   # the association class, but that would make it different from
        #   # real associations, which read has_one vs. belongs_to from the
        #   # model.
        #   associations[association.key] = { model_association => association.key }
        end
        #associations[association_name][:async] = (association.options[:async] || false) if association.options.has_key? :async
      end

      return { :attributes => attrs, :associations => associations }
    end

    def self.inherited_schema(serializer, klass, base_schema)
      schema = schema(serializer, klass)

      schema_diff = {}
      schema_diff[:attributes] = diff(base_schema[:attributes], schema[:attributes])
      schema_diff[:associations] = diff(base_schema[:associations], schema[:associations])
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
