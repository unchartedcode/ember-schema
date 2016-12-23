module Ember
  module Schema
    class JsonapiResource
      def superclass
        ::JSONAPI::Resource
      end

      def serializers
        Dir["#{Rails.root}/app/resources/**/*_resource.rb"].map { |f|
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

        (serializer._attributes || {}).each do |name, o|
          options = o.dup

          attribute_format = options.delete(:format)
          attribute_type = options.delete(:type)

          if attribute_format.present?
            options[:type] = convert_format(attribute_format, attribute_type)
          end

          if options[:type].blank?
            # If no type is given, attempt to get it from the Active Model class
            if column = columns[name.to_s]
              options[:type] = convert_format(column.type, attribute_type || column.type)
            end
          end

          if options[:type].blank?
            options[:type] = 'string'
          end

          attribute_default = options.delete(:default)
          unless attribute_default.nil?
            options[:defaultValue] = convert_default(attribute_default)
          end

          if options[:defaultValue].nil? && columns[name.to_s].present? && columns[name.to_s].null == false
            options[:defaultValue] = convert_default(columns[name.to_s].default)
          end

          if options[:defaultValue].nil?
            options.delete(:defaultValue)
          end

          if options[:immutable].present?
            options[:readOnly] = options.delete(:immutable)
          end

          attrs[name] = options
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

          # Converting these to match how they used to be
          prefixes = ['project', 'product', 'order', 'company', 'user']
          prefix = prefixes.select { |p| "#{relationship.type}".starts_with?("#{p}_") }.first
          if prefix.present?
            associations[name] = { type => "#{relationship.type}".gsub(/#{prefix}_/, "#{prefix}/") }
          else
            associations[name] = { type => relationship.type }
          end
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

      def convert_default(value)
        if value.is_a? BigDecimal
          value.to_f
        else
          value
        end
      end
    end
  end
end
