module Ember
  module Schema
    class JsonapiResource
      def superclass
        ::JSONAPI::Resource
      end

      def serializers
        Dir["#{Rails.root}/app/resources/**/*.rb"].map { |f|
          f.gsub(/#{Rails.root}\/app\/resources\//, '').gsub("_resource#{File.extname(f)}",'')
        }.map { |f|
          JSONAPI::Resource.resource_for(f)
        }.select { |f|
          !f._abstract
        }
      end

      def descendants(serializer)
        serializer.descendants.sort_by { |s| s.name }
      end

      def get_klass(serializer)
        serializer._model_class
      end

      def camelize(serializer, klass)
        klass.name.camelize
      end

      def schema(serializer, klass)
        columns = if klass.respond_to? :columns_hash then klass.columns_hash else {} end

        attrs = {}
        (serializer._attributes || {}).each do |name, options|
          type = nil
          if options[:format].present?
            type = convert_format(options[:format], options[:type])
          end

          if type.blank?
            # If no type is given, attempt to get it from the Active Model class
            if column = columns[name.to_s]
              type = convert_format(column.type, options[:type] || column.type)
            end
          end
          attrs[name] = (type || "string").to_s
        end

        associations = {}

        serializer._relationships.each do |name, relationship|
          type = case relationship
                   when JSONAPI::Relationship::ToOne
                     :belongs_to
                   when JSONAPI::Relationship::ToMany
                     :has_many
                   else
                     fail "Relationship #{relationship} not found"
                 end
          associations[name] = { type => relationship.type }
        end

        return { :attributes => attrs, :associations => associations }
      end

      def abstract?(serializer)
        serializer._abstract
      end

      def convert_format(format, default=nil)
        case format
          when :id
            :integer
          when :text
            :string
          else
            default
        end
      end
    end
  end
end
