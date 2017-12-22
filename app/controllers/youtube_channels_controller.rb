class YoutubeChannelsController < ApplicationController
  include ChannelsHelper

  before_action :authenticate_publisher!

  # def new
  #   @channel = Channel.new(publisher: current_publisher, details: SiteChannelDetails.new)
  #
  #   respond_to do |format|
  #     format.html
  #   end
  # end
  #
  # def create
  #   @current_channel = Channel.new(publisher: current_publisher)
  #   current_channel.details = SiteChannelDetails.new(channel_update_unverified_params)
  #
  #   respond_to do |format|
  #     if current_channel.save
  #       format.html {redirect_to(channel_next_step_path(current_channel), notice: t("channel.channel_created")) }
  #     else
  #       format.html {render :action => "new"}
  #     end
  #   end
  # end
end
