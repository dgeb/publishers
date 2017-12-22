class Channel < ApplicationRecord
  has_paper_trail

  belongs_to :publisher
  belongs_to :details, polymorphic: true, validate: true, autosave: true, optional: false
  belongs_to :site_channel_details, -> { where( channels: { details_type: 'SiteChannelDetails' } ).includes( :channels ) }, foreign_key: 'details_id'
  belongs_to :youtube_channel_details, -> { where( channels: { details_type: 'YoutubeChannelDetails' } ).includes( :channels ) }, foreign_key: 'details_id'

  accepts_nested_attributes_for :details

  validate :details_not_changed?

  scope :site_channels, -> {
    joins(:site_channel_details)
  }
  scope :youtube_channels, -> {
    joins(:youtube_channel_details)
  }
  # Once the verification_method has been set it shows we have presented the publisher with the token. We need to
  # ensure this site_channel will be preserved so the publisher cna come back to it.
  scope :visible_site_channels, -> {
    left_outer_joins(:site_channel_details).
        where('site_channel_details.verified': true).
        or(Channel.left_outer_joins(:site_channel_details).where.not('site_channel_details.verification_method': nil))
  }
  scope :visible_youtube_channels, -> {
    left_outer_joins(:youtube_channel_details).
        where.not('youtube_channel_details.youtube_channel_id': nil)
  }

  # ToDo: figure out how we want to do this
  scope :visible_channels, -> {
    Channel.visible_site_channels.or(Channel.visible_youtube_channels)
  }

  def publication_title
    details.publication_title
  end

  def details_not_changed?
    unless details_id_was.nil? || (details_id == details_id_was && details_type == details_type_was)
      errors.add(:details, "can't be changed")
    end
  end
end