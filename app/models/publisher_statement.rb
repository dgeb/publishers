class PublisherStatement < ApplicationRecord
  EXPIRE_AFTER = 1.day

  attr_encrypted :s3_key, key: :encryption_key

  belongs_to :publisher
  validates :publisher_id, presence: true
  validates :period,
            inclusion: { in: %w(past_7_days past_30_days this_month last_month this_year last_year all) },
            presence: true

  after_create :set_expiration

  def set_expiration
    self.expires_at = Time.zone.now + EXPIRE_AFTER
    save!
  end

  def expired?
    Time.zone.now > self.expires_at
  end
end
