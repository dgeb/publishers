require "test_helper"

class ChannelTest < ActiveSupport::TestCase

  test "site channel must have details" do
    channel = channels(:verified)
    assert channel.valid?

    assert_equal "verified.org", channel.details.brave_publisher_id
  end

  test "youtube channel must have details" do
    channel = channels(:google_verified)
    assert channel.valid?

    assert_equal "Some Other Guy's Channel", channel.details.youtube_channel.title
  end

  test "channel can not change details" do
    channel = channels(:google_verified)
    assert channel.valid?

    channel.details = site_channel_details(:uphold_connected_details)
    refute channel.valid?

    assert_equal "can't be changed", channel.errors.messages[:details][0]
  end
end
