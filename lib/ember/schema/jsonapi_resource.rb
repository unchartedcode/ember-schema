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
          if options[:format].present?
            attrs[name] = convert_format(options[:format]).to_s
          else
            # If no type is given, attempt to get it from the Active Model class
            if column = columns[name.to_s]
              attrs[name] = convert_format(column.type)
            else
              # Other wise default to string
              attrs[name] = "string"
            end
          end
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

      def convert_format(format)
        case format
          when :id
            :integer
          when :text
            :string
          else
            format
        end
      end
    end
  end
end
