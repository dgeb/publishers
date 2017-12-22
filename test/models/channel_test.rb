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

    assert_equal "Some Other Guy's Channel", channel.details.title
  end

  test "channel can not change details" do
    channel = channels(:google_verified)
    assert channel.valid?

    channel.details = site_channel_details(:uphold_connected_details)
    refute channel.valid?

    assert_equal "can't be changed", channel.errors.messages[:details][0]
  end

  test "publication_title is the site domain for site publishers" do
    channel = channels(:verified)
    assert_equal 'verified.org', channel.details.brave_publisher_id
    assert_equal 'verified.org', channel.details.publication_title
    assert_equal 'verified.org', channel.publication_title
  end

  test "publication_title is the youtube channel title for youtube creators" do
    channel = channels(:youtube_new)
    assert_equal 'The DIY Channel', channel.details.title
    assert_equal 'The DIY Channel', channel.details.publication_title
    assert_equal 'The DIY Channel', channel.publication_title
  end

  # ToDo:
  # test "a publisher cannot change youtube channels" do
  #   publisher = publishers(:youtube_initial)
  #   assert publisher.valid?
  #
  #   some_channel = youtube_channels(:some_channel)
  #   publisher.youtube_channel = some_channel
  #   assert publisher.valid?
  #
  #   publisher.save
  #
  #   some_other_channel = youtube_channels(:some_other_channel)
  #   publisher.youtube_channel = some_other_channel
  #   refute publisher.valid?
  # end
  #
  # test "a publisher cannot have the same youtube channel as another publisher" do
  #   publisher = publishers(:youtube_initial)
  #   assert publisher.valid?
  #
  #   diy_channel = youtube_channels(:diy_channel)
  #   publisher.youtube_channel = diy_channel
  #   refute publisher.valid?
  # end
  #
  # test "a site channel assigned a brave_publisher_id_error_code and brave_publisher_id will not be valid" do
  #   publisher = Publisher.new
  #
  #   publisher.pending_email = "foo@bar.com"
  #   publisher.email = "foo@bar.com"
  #   publisher.name = 'Joe Blow'
  #
  #   assert publisher.valid?
  #
  #   publisher.brave_publisher_id = 'asdf asdf'
  #   publisher.brave_publisher_id_error_code = :invalid_uri
  #
  #   refute publisher.valid?
  #   assert_equal [:"channel.details.brave_publisher_id"], publisher.errors.keys
  #   assert_equal "invalid_uri", publisher.brave_publisher_id_error_code
  #   assert_equal I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.invalid_uri"), publisher.brave_publisher_id_error_description
  # end
  #
  # test "a publisher assigned a brave_publisher_id_error_code and brave_publisher_id_unnormalized will not be valid" do
  #   publisher = Publisher.new
  #
  #   publisher.pending_email = "foo@bar.com"
  #   publisher.brave_publisher_id_unnormalized = 'asdf asdf'
  #   assert publisher.save
  #
  #   publisher.brave_publisher_id_error_code = :invalid_uri
  #
  #   refute publisher.valid?
  #   assert_equal [:brave_publisher_id_unnormalized], publisher.errors.keys
  #   assert_equal "invalid_uri", publisher.brave_publisher_id_error_code
  #   assert_equal I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.invalid_uri"), publisher.brave_publisher_id_error_description
  # end


end
