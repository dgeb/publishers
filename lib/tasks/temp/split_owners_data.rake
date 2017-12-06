namespace :publishers do
  desc "Populate from old Publishers data"
  task transform_publishers: :environment do
    publishers = Publisher.all
    puts "Going to update #{publishers.count} publishers"

    ActiveRecord::Base.transaction do

    end

    puts " All done now!"
  end

end