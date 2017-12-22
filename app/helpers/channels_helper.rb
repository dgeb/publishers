module ChannelsHelper

  def current_channel
    @current_channel
  end

  def site_last_verification_method_path(channel)
    case channel.details.verification_method
      when "dns_record"
        verification_dns_record_site_channel_path(channel)
      when "public_file"
        verification_public_file_site_channel_path(channel)
      when "github"
        verification_github_site_channel_path(channel)
      when "wordpress"
        verification_wordpress_site_channel_path(channel)
      when "support_queue"
        verification_support_queue_site_channel_path(channel)
      else
        verification_choose_method_site_channel_path(channel)
    end
  end

  def site_channel_next_step_path(channel)
    if channel.details.verified?
      # ToDo: Do we have a channel home?
      home_publishers_path
    else
      site_last_verification_method_path(channel)
    end
  end

  def youtube_channel_next_step_path(channel)
    # ToDo: Do we have a channel home?
    home_publishers_path
  end

  def channel_next_step_path(channel)
    case channel.details
      when SiteChannelDetails
        site_channel_next_step_path(channel)
      when YoutubeChannelDetails
        youtube_channel_next_step_path(channel)
      else
        home_publishers_path(channel.publisher)
    end
  end

  def site_channel_filtered_verification_token(channel)
    if channel.details.supports_https?
      channel.details.verification_token
    else
      # ToDo: Do we want to display a fake token? Will show up in disabled forms
      ""
    end
  end

  def site_channel_filter_public_file_content(channel, file_content)
    if channel.details.supports_https?
      file_content
    else
      # ToDo: Do we want to display a fake token? Will show up in disabled forms
      ""
    end
  end

  def site_channel_verification_dns_record(channel)
    SiteChannelDnsRecordGenerator.new(channel: channel).perform
  end

end