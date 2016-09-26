task :import_data => :environment do
  Episode.set_up_data
end
