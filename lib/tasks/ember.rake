namespace :db do
  namespace :schema do
    desc 'Regenerate the Ember schema.js based on the serializers'
    task :ember => :environment do
      schema_hash = Ember::Schema.generate
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
if ActiveRecord::Base.dump_schema_after_migration
  namespace :db do
    task :_dump => [ 'db:schema:ember' ]
  end
else
  namespace :db do
    task :migrate do
      Rake::Task['db:schema:ember'].invoke
    end

    namespace :migrate do
      [:change, :up, :down, :reset, :redo].each do |t|
        task t do
          Rake::Task['db:schema:ember'].invoke
        end
      end
    end
  end
end
