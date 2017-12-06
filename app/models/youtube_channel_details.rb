class YoutubeChannelDetails < ApplicationRecord
  has_paper_trail

  has_one :channel, as: :details

  belongs_to :youtube_channel

  validate :youtube_channel_not_changed_once_initialized
  validates_uniqueness_of :youtube_channel_id, if: -> { youtube_channel_id.present? }

  private

  # verification to ensure youtube_channel is not changed
  def youtube_channel_not_changed_once_initialized
    return if youtube_channel_id_was.nil?

    if youtube_channel_id_was != youtube_channel_id
      errors.add(:youtube_channel_id, "can not change once initialized")
    end
  end

  def self.youtube_channel_in_use(id)
    self.where(youtube_channel_id: id).count > 0
  end

end