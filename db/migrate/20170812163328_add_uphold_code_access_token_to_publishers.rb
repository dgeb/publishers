class AddUpholdCodeAccessTokenToPublishers < ActiveRecord::Migration[5.0]
  def change
    change_table :publishers do |t|
      t.string :uphold_code
      t.string :uphold_access_token
    end
  end
end
