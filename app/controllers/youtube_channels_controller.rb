class YoutubeChannelsController < ApplicationController
  include ChannelsHelper

  before_action :authenticate_publisher!

  def new
    @channel = Channel.new(publisher: current_publisher, details: SiteChannelDetails.new)

    respond_to do |format|
      format.html
    end
  end

  def create
    @current_channel = Channel.new(publisher: current_publisher)
    current_channel.details = SiteChannelDetails.new(channel_update_unverified_params)

    # ToDo: Reinstate the asynchronous handling of publisher_id.
    # SetPublisherDomainJob.perform_later(publisher_id: @publisher.id)
    current_channel.details.brave_publisher_id = current_channel.details.brave_publisher_id_unnormalized

    respond_to do |format|
      if current_channel.save
        format.html {redirect_to(channel_next_step_path(current_channel), :notice => 'ToDo: Channel was successfully created.')}
      else
        format.html {render :action => "new"}
      end
    end
  end


end
