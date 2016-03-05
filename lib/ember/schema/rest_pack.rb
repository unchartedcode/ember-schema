module Ember
  module Schema
    class RestPack
      def superclass
        ::RestPack::Serializer
      end

      def serializers
        ::RestPack::Serializer.class_map.sort_by { |s| s[0] }.map { |s| s[1] }
      end

      def descendants(serializer)
        serializer.descendants.sort_by { |s| s.name }
      end

      def get_klass(serializer)
        serializer.model_class
      end

      def camelize(serializer, klass)
        klass.name.camelize
      end

      def schema(serializer, klass)
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
          if model_association = klass.reflect_on_association(association_name)
            # Real association
            associations[association_name] = { model_association.macro => model_association.class_name.pluralize.underscore.downcase }
          end
        end

        return { :attributes => attrs, :associations => associations, :defaults => {} }
      end

      def abstract?(serializer_class)
        serializer_class == ApplicationSerializer ||
        (serializer_class.respond_to?(:ignore) && serializer_class.ignore)
      end
    end
  end
end
