module Ember
  module Schema
    class ActiveModel
      def superclass
        ::ActiveModel::Serializer
      end

      def serializers
        ::ActiveModel::Serializer.descendants.sort_by(&:final_name)
      end

      def descendants(serializer)
        serializers
      end

      def get_klass(serializer)
        module_name = serializer.name.deconstantize
        class_name = serializer.root_name.camelize
        full_name = [module_name, class_name].reject(&:empty?).join("::")
        begin
          return full_name.constantize
        rescue => e
          p " - Unable to find model: '#{full_name}'. Skipping schema processing."
          return nil
        end
      end

      def camelize(serializer, klass)
        (serializer._root || klass.name).camelize
      end

      def schema(serializer, klass)
        columns = if klass.respond_to? :columns_hash then klass.columns_hash else {} end

        attrs = {}
        serializer._attributes.each do |name|
          option = serializer._options[name] || {}
          if option[:type].present?
            attrs[name] = option[:type]
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
        serializer._associations.each do |attr, association|
          #association = association_class.new(attr, self)

          if model_association = get_type(association)
            # Real association.
            association_class_name = association.options[:class_name]
            key = association.key.gsub(/_id/,'')
            associations[key] = { model_association => association_class_name || key }
            associations[key][:async] = (association.options[:async] || false) if association.options.has_key? :async
            associations[key][:polymorphic] = (association.options[:polymorphic] || false) if association.options.has_key? :polymorphic
          else
            # Computed association. We could infer has_many vs. has_one from
            # the association class, but that would make it different from
            # real associations, which read has_one vs. belongs_to from the
            # model.
            associations[association.key] = nil
          end
        end

        return { :attributes => attrs, :associations => associations, :defaults => {} }
      end

      def abstract?(serializer_class)
        serializer_class == ApplicationSerializer ||
        (serializer_class.respond_to?(:ignore) && serializer_class.ignore)
      end

      def get_type(association)
        if association.is_a? ::ActiveModel::Serializer::Association::HasMany
          return "has_many"
        elsif association.is_a? ::ActiveModel::Serializer::Association::HasOne
          return "belongs_to"
        end
        return nil
      end
    end
  end
end
