class SiteChannelsController < ApplicationController
  include ChannelsHelper

  before_action :authenticate_publisher!
  before_action :setup_current_channel,
                except: %i(new
               create)
  before_action :require_unverified_site,
                only: %i(email_verified
             contact_info
             domain_status
             update_unverified
             verification
             verification_choose_method
             verification_dns_record
             verification_wordpress
             verification_github
             verification_public_file
             verification_support_queue
             verification_background
             verify
             download_verification_file)
  before_action :require_https_enabled_site,
                only: %i(download_verification_file)
  before_action :update_site_verification_method,
                only: %i(verification_dns_record
             verification_public_file
             verification_support_queue
             verification_github
             verification_wordpress)

  def new
    @channel = Channel.new(publisher: current_publisher, details: SiteChannelDetails.new)

    respond_to do |format|
      format.html
    end
  end

  def create
    @current_channel = Channel.new(publisher: current_publisher)
    current_channel.details = SiteChannelDetails.new(channel_update_unverified_params)

    SetChannelDomainJob.perform_later(channel_id: current_channel.id)
    current_channel.details.brave_publisher_id = current_channel.details.brave_publisher_id_unnormalized

    respond_to do |format|
      if current_channel.save
        format.html { redirect_to(channel_next_step_path(current_channel), notice: t("channel.channel_created")) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    # current_channel.details.update(channel_update_verified_params)
  end

  def verification_github
    generator = SiteChannelVerificationFileGenerator.new(site_channel: current_channel)
    @public_file_content = generator.generate_file_content
  end

  # TODO: Rate limit
  def check_for_https
    @channel = current_channel
    @channel.details.inspect_brave_publisher_id
    @channel.save!
    redirect_to(site_last_verification_method_path(@channel), alert: t("publishers.https_inspection_complete"))
  end

  # Tied to button on verification_dns_record
  # Call to Eyeshade to perform verification
  # TODO: Rate limit
  # TODO: Support XHR
  def verify
    @channel = current_channel
    require "faraday"
    SiteChannelVerifier.new(
        brave_publisher_id: current_channel.details.brave_publisher_id,
        channel: current_channel
    ).perform
    current_channel.details.reload
    if current_channel.details.verified?
      redirect_to(home_publishers_path)
    else
      render(:verification_background)
    end
  rescue SiteChannelVerifier::VerificationIdMismatch
    redirect_to(site_last_verification_method_path(@channel), alert: t("activerecord.errors.models.publisher.attributes.brave_publisher_id.taken"))
  rescue Faraday::Error
    redirect_to(publisher_last_verification_method_path(@channel), alert: t("shared.api_error"))
  end

  private
  def channel_update_unverified_params
    params.require(:channel).require(:details_attributes).permit(:brave_publisher_id_unnormalized)
  end

  def setup_current_channel
    @current_channel = Channel.site_channels.find(params[:id])
    return if @current_channel && @current_channel.publisher == current_publisher
    redirect_to(home_publishers_path(current_publisher), alert: I18n.t("channel.requires_other_channel_type"))
  end

  def require_unverified_site
    return if !current_channel.details.verified?
    redirect_to(channel_next_step_path(current_channel), alert: I18n.t("publishers.verification_already_done"))
  end

  def require_https_enabled_site
    return if current_channel.details.supports_https?
    redirect_to(site_last_verification_method_path(current_channel.details), alert: t("publishers.requires_https"))
  end

  def update_site_verification_method
    case params[:action]
      when "verification_dns_record"
        current_channel.details.verification_method = "dns_record"
      when "verification_public_file"
        current_channel.details.verification_method = "public_file"
      when "verification_github"
        current_channel.details.verification_method = "github"
      when "verification_wordpress"
        current_channel.details.verification_method = "wordpress"
      when "verification_support_queue"
        current_channel.details.verification_method = "support_queue"
      else
        raise "unknown action"
    end
    current_channel.details.save! if current_channel.details.verification_method_changed?
  end
end