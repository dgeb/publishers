class SiteChannelDetails < ApplicationRecord
  has_paper_trail

  has_one :channel, as: :details

  # brave_publisher_id is a normalized identifier provided by ledger API
  # It is like base domain (eTLD + left part) but may include additional
  # formats to support more publishers.
  validates :brave_publisher_id, uniqueness: { if: -> { brave_publisher_id.present? && brave_publisher_id_changed? && verified_publisher_id_exists? } }

  # - normalized and unnormalized domains
  # - normalized domains and domain-related errors
  validates :brave_publisher_id, absence: true, if: -> { brave_publisher_id_error_code.present? || brave_publisher_id_unnormalized.present? }
  validate :brave_publisher_id_not_changed_once_initialized

  before_validation :register_brave_publisher_id_error, if: -> { brave_publisher_id_unnormalized.present? && brave_publisher_id_error_code.present? }

  # clear/register domain errors as appropriate
  before_validation :clear_brave_publisher_id_error, if: -> { brave_publisher_id_unnormalized.present? && brave_publisher_id_unnormalized_changed? }

  after_validation :generate_verification_token, if: -> { brave_publisher_id.present? && brave_publisher_id_changed? }

  def initialized?
    brave_publisher_id.present? || brave_publisher_id_unnormalized.present?
  end

  def publication_title
    brave_publisher_id || brave_publisher_id_unnormalized
  end

  def brave_publisher_id_error_description
    case self.brave_publisher_id_error_code.to_sym
      when :exclusion_list_error
        "#{I18n.t('activerecord.errors.models.publisher.attributes.brave_publisher_id.exclusion_list_error')} #{Rails.application.secrets[:support_email]}"
      when :api_error_cant_normalize
        I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.api_error_cant_normalize")
      when :invalid_uri
        I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.invalid_uri")
      else
        raise "Unrecognized brave_publisher_id_error_code: #{self.brave_publisher_id_error_code}"
    end
  end

  def inspect_brave_publisher_id
    require "faraday"
    result = SiteChannelHostInspector.new(brave_publisher_id: self.brave_publisher_id).perform
    if result[:host_connection_verified]
      self.supports_https = result[:https]
      self.detected_web_host = result[:web_host]
      self.host_connection_verified = true
    else
      self.supports_https = false
      self.detected_web_host = nil
      self.host_connection_verified = false
    end
  end

  private

  def generate_verification_token
    update_attribute(:verification_token, PublisherTokenRequester.new(publisher: self).perform)
  end

  def verified_publisher_id_exists?
    self.class.joins(:channel).where(brave_publisher_id: brave_publisher_id, "channels.verified": true).any?
  end

  def clear_brave_publisher_id_error
    self.brave_publisher_id_error_code = nil
  end

  def register_brave_publisher_id_error
    self.errors.add(
        :brave_publisher_id_unnormalized,
        self.brave_publisher_id_error_description
    )
  end

  # verification to ensure brave_publisher_id is not changed
  def brave_publisher_id_not_changed_once_initialized
    return if brave_publisher_id_was.nil?

    if brave_publisher_id_was != brave_publisher_id
      errors.add(:brave_publisher_id, "can not change once initialized")
    end
  end
end