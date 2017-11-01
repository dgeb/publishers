class PublisherYoutubeChannelSyncer
  attr_reader :publisher

  def initialize(publisher:, token:)
    @publisher = publisher
    @token = token
  end

  def perform
    # Get the channel information. Will search for the token identified user's channel, or of it's already
    # set grab a refresh
    channel_json = YoutubeChannelGetter.new(publisher: @publisher,
                                            token: @token,
                                            channel_id: @publisher.youtube_channel_id).perform
    channel_attrs = {
        title: channel_json['snippet']['title'],
        description: channel_json['snippet']['description'],
        thumbnail_url: channel_json['snippet']['thumbnails']['default']['url'],
        subscriber_count: channel_json['statistics']['subscriberCount']
    }

    # Create or update the youtube channel
    if publisher.youtube_channel
      publisher.youtube_channel.update(channel_attrs)
      publisher.youtube_channel.save!
    else
      channel_attrs[:id] = channel_json['id']

      channel = YoutubeChannel.new(channel_attrs)
      channel.save!
      publisher.youtube_channel = channel
      publisher.save!
    end
  end
end
