namespace :db do
  namespace :schema do
    desc 'Regenerate the Ember schema.js based on the serializers'
    task :ember => :environment do
      if defined? JSONAPI::Resource
        schema_hash = Ember::Schema.generate(JSONAPI::Resource)
      else
        Rails.application.eager_load! # populate descendants
        schema_hash = Ember::Schema.generate(ActiveModel::Serializer)
      end

      schema_json = JSON.pretty_generate(schema_hash)
      File.open 'db/schema.js', 'w' do |f|
        f << schema_json
      end
    end
  end
end

##
# Automatically generate schema when migration changes occur
##
[
  "db:migrate",
  "db:migrate:up",
  "db:migrate:down",
  "db:migrate:reset",
  "db:migrate:redo"
].each do |task|
  Rake::Task[task].enhance ["db:schema:ember"]
end
