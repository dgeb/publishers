require "test_helper"

class SiteChannelTest < ActiveSupport::TestCase

  test "a channel cannot change brave_publisher_id" do
    details = site_channel_details(:verified_details)
    assert details.valid?

    details.brave_publisher_id = "foo.com"
    refute details.valid?
  end

  test "a channel cannot have the same brave_publisher_id as another verified channel" do
    details = site_channel_details(:verified_details)
    assert details.valid?

    # Does not exist
    new_details = SiteChannelDetails.new(brave_publisher_id: "sdffadsdfsa.com")
    assert new_details.valid?

    # Exists, but not verified
    new_details = SiteChannelDetails.new(brave_publisher_id: "default.org")
    assert new_details.valid?

    # Exists and is verified
    new_details = SiteChannelDetails.new(brave_publisher_id: "verified.org")
    refute new_details.valid?
  end

  test "a site channel assigned a brave_publisher_id_error_code and brave_publisher_id will not be valid" do
    details = SiteChannelDetails.new
    assert details.valid?

    details.brave_publisher_id = 'asdf asdf'
    details.brave_publisher_id_error_code = :invalid_uri

    refute details.valid?
    assert_equal [:"brave_publisher_id"], details.errors.keys
    assert_equal "invalid_uri", details.brave_publisher_id_error_code
    assert_equal I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.invalid_uri"), details.brave_publisher_id_error_description
  end

  test "a site channel assigned a brave_publisher_id_error_code and brave_publisher_id_unnormalized will not be valid" do
    details = SiteChannelDetails.new
    details.brave_publisher_id_unnormalized = 'asdf asdf'
    assert details.save

    details.brave_publisher_id_error_code = :invalid_uri

    refute details.valid?
    assert_equal [:brave_publisher_id_unnormalized], details.errors.keys
    assert_equal "invalid_uri", details.brave_publisher_id_error_code
    assert_equal I18n.t("activerecord.errors.models.publisher.attributes.brave_publisher_id.invalid_uri"), details.brave_publisher_id_error_description
  end
end
