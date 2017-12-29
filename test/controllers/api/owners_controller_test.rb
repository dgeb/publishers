require "test_helper"
require "shared/mailer_test_helper"

class Api::OwnersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  PUBLISHER_PARAMS = {
    publisher: {
      email: "alice@example.com",
      name: "Alice the Pyramid",
      phone: "+14159001420"
    }
  }.freeze

  VERIFIED_PUBLISHER_PARAMS = PUBLISHER_PARAMS.deep_merge(
    publisher: {
      verified: true
    }
  ).freeze

  # test "show_verification_status returns as false if nil" do
  #   default_publisher = publishers(:default)
  #   assert_nil default_publisher.show_verification_status
  #
  #   get "/api/publishers/#{default_publisher.brave_publisher_id}"
  #
  #   assert_equal(200, response.status)
  #   refute_nil JSON.parse(response.body)[0]['show_verification_status']
  # end
  #
  # test "show_verification_status returns as true if true" do
  #   uphold_connected = publishers(:uphold_connected)
  #   assert uphold_connected.show_verification_status
  #
  #   get "/api/publishers/#{uphold_connected.brave_publisher_id}"
  #
  #   assert_equal(200, response.status)
  #   assert JSON.parse(response.body)[0]['show_verification_status']
  # end
  #
  # test "returns error for omitted notification type" do
  #   verified_publisher = publishers(:verified)
  #
  #   post "/api/publishers/#{verified_publisher.brave_publisher_id}/notifications"
  #
  #   assert_equal 400, response.status
  #   assert_match "parameter 'type' is required", response.body
  # end
  #
  # test "returns error for invalid notification type" do
  #   verified_publisher = publishers(:verified)
  #
  #   post "/api/publishers/#{verified_publisher.brave_publisher_id}/notifications?type=invalid_type"
  #
  #   assert_equal 400, response.status
  #   assert_match "invalid", response.body
  # end
  #
  # test "send email for valid notification type" do
  #   verified_publisher = publishers(:verified)
  #
  #   assert_enqueued_emails 2 do
  #     post "/api/publishers/#{verified_publisher.brave_publisher_id}/notifications?type=verified_no_wallet"
  #   end
  #
  #   assert_equal 200, response.status
  # end

  test "can get owner by owner_identifier" do
    owner = publishers(:verified)

    get "/api/owners/#{URI.escape(owner.owner_identifier)}"
    puts response.body

    assert_equal 200, response.status
  end
end
