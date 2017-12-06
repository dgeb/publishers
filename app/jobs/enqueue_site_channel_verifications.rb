# For Publishers created recently, enqueue jobs to verify each unique
# brave_publisher_id.
class EnqueueSiteChannelVerifications < ApplicationJob
  MAX_AGE = 6.weeks

  queue_as :scheduler

  def perform
    n = 0
    brave_publisher_ids.each do |brave_publisher_id|
      VerifySiteChannel.perform_later(brave_publisher_id: brave_publisher_id)
      n += 1
    end
    Rails.logger.info("EnqueueSiteChannelVerifications enqueued VerifySiteChannels #{n} times.")
  end

  private

  # Get distinct unverified brave_publisher_ids created recently.
  def brave_publisher_ids
    SiteChannelDetails
      .select(:brave_publisher_id).distinct
      .where.not(brave_publisher_id: SiteChannelDetails.joins(:channel).select(:brave_publisher_id).distinct.where(verified: true))
      .where(created_at: MAX_AGE.ago..Time.now)
      .pluck(:brave_publisher_id)
  end
end
