class AddOmniauthToPublishers < ActiveRecord::Migration[5.0]
  def change
    add_column :publishers, :provider, :string
    add_column :publishers, :provider_user_id, :string
  end
end
