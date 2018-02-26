class AddVerificationTimestampsToSiteChannels < ActiveRecord::Migration[5.0]
  def change
    add_column :site_channel_details, :verification_started, :datetime
    add_column :site_channel_details, :verification_failed, :datetime
  end
end
