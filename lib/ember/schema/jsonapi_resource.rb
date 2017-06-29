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
          column = columns[name.to_s]

          # Always remove the format, we don't want it passed through to schema
          options.delete(:format)

          # Get the default from the column whenever possible if type isn't passed in
          if options[:type].nil?
            if column.present?
              options[:type] = get_type_from_column(column)
            else
              options[:type] = :string
            end
          end

          # Set defaultValue from default alias
          if !options[:default].nil?
            options[:defaultValue] = options.delete(:default)
          end

          # If default is still nil, try to get it from the column
          if options[:defaultValue].nil? && column.present?
            options[:defaultValue] = get_default_from_column(column)
          end

          # If we don't have a default, just remove the key
          if options[:defaultValue].nil?
            options.delete(:defaultValue)
          end

          # Get immutable value
          if options[:immutable] == true || serializer._immutable == true
            options[:readOnly] = true
          end
          # Always remove immutable, we don't want it passed through to schema
          options.delete(:immutable)

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

      def get_type_from_column(column)
        if column.array == true
          return :array
        end

        if column.type == :text
          return :string
        end

        column.type
      end

      def get_default_from_column(column)
        if column.default.nil?
          return nil
        end

        if column.array == true
          return []
        end

        if column.type == :integer
          return column.default.to_i
        end

        if column.type == :jsonb
          return {}
        end

        if column.type == :boolean
          if column.default == "true"
            return true
          end
          return false
        end

        column.default
      end
    end
  end
end
