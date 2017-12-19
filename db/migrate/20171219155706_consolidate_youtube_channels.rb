class ConsolidateYoutubeChannels < ActiveRecord::Migration[5.0]
  def change
    # Combines the channel

    # Rename existing youtube_channels tables
    rename_table :youtube_channels, :legacy_youtube_channels

    # move columns from youtube_channels to youtube_channels_details
    change_table :youtube_channel_details do |t|
      t.string   :title
      t.string   :description
      t.string   :thumbnail_url
      t.integer  :subscriber_count
    end
  end
end
