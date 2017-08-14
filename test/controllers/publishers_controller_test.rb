require "test_helper"
require "shared/mailer_test_helper"

class PublishersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionMailer::TestHelper
  include MailerTestHelper
  include PublishersHelper

  PUBLISHER_PARAMS = {
    publisher: {
      email: "alice@example.com",
      brave_publisher_id: "pyramid.net",
      name: "Alice the Pyramid",
      phone: "+14159001420"
    }
  }.freeze

  test "new action has a create form" do
    get(new_publisher_path)
    assert_response(:success)
    assert_select("form[action=\"#{publishers_path}\"]")
  end

  test "can create a Publisher registration, pending email verification" do
    get(new_publisher_path)
    assert_difference("Publisher.count") do
      # Confirm email + Admin notification
      assert_enqueued_emails(2) do
        post(publishers_path, params: PUBLISHER_PARAMS)
      end
    end
    assert_redirected_to(create_done_publishers_path)
    publisher = Publisher.order(created_at: :asc).last
    get(publisher_path(publisher))
    assert_redirected_to(root_path)
  end

  test "sends an email with an access link" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
      publisher = Publisher.order(created_at: :asc).last
      email = ActionMailer::Base.deliveries.find do |message|
        message.to.first == PUBLISHER_PARAMS[:publisher][:email]
      end
      assert_not_nil(email)
      url = publisher_url(publisher, token: publisher.authentication_token)
      assert_email_body_matches(matcher: url, email: email)
    end
  end

  test "access link logs the user in, and works only once" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
    end
    publisher = Publisher.order(created_at: :asc).last
    url = publisher_url(publisher, token: publisher.authentication_token)
    get(url)
    follow_redirect!
    assert_select("[data-test-id='current_publisher']", publisher.to_s)
    sign_out(:publisher)
    get(url)
    assert_empty(css_select("[data-test-id='current_publisher']"))
  end

  def request_login_email(publisher:)
    perform_enqueued_jobs do
      get(new_auth_token_publishers_path)
      params = { publisher: publisher.attributes.slice(*%w(brave_publisher_id email)) }
      post(create_auth_token_publishers_path, params: params)
    end
  end

  test "relogin sends a login link email" do
    publisher = publishers(:default)
    request_login_email(publisher: publisher)
    email = ActionMailer::Base.deliveries.find do |message|
      message.to.first == publisher.email
    end
    assert_not_nil(email)
    url = publisher_url(publisher, token: publisher.reload.authentication_token)
    assert_email_body_matches(matcher: url, email: email)
  end

  test "relogin email works only once" do
    publisher = publishers(:default)
    request_login_email(publisher: publisher)
    url = publisher_url(publisher, token: publisher.reload.authentication_token)
    get(url)
    follow_redirect!
    assert_select("[data-test-id='current_publisher']", publisher.to_s)
    sign_out(:publisher)
    get(url)
    assert_empty(css_select("[data-test-id='current_publisher']"))
  end

  test "relogin for unverified publishers requires email" do
    publisher = publishers(:default)
    assert_enqueued_jobs(0) do
      get(new_auth_token_publishers_path)
      params = { publisher: publisher.attributes.slice(*%w(brave_publisher_id)) }
      post(create_auth_token_publishers_path, params: params)
    end
  end

  test "relogin for unverified publishers fails with the wrong email" do
    publisher = publishers(:default)
    assert_enqueued_jobs(0) do
      get(new_auth_token_publishers_path)
      params = { publisher: { "brave_publisher_id" => publisher.brave_publisher_id, "email" => "anon@cock.li" } }
      post(create_auth_token_publishers_path, params: params)
    end
  end

  test "relogin for verified publishers without an email sends to the publisher's email" do
    publisher = publishers(:verified)
    perform_enqueued_jobs do
      get(new_auth_token_publishers_path)
      params = { publisher: publisher.attributes.slice(*%w(brave_publisher_id)) }
      post(create_auth_token_publishers_path, params: params)
    end
    email = ActionMailer::Base.deliveries.find do |message|
      message.to.first == publisher.email
    end
    assert_not_nil(email)
    url = publisher_url(publisher, token: publisher.reload.authentication_token)
    assert_email_body_matches(matcher: url, email: email)
  end

  test "after verification, a publisher's `uphold_state_token` is set and will be used for Uphold authorization" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
    end
    publisher = Publisher.order(created_at: :asc).last
    url = publisher_url(publisher, token: publisher.authentication_token)
    get(url)
    follow_redirect!

    # skip publisher verification
    publisher.verified = true
    publisher.save!

    # verify that the state token has not yet been set
    assert_nil(publisher.uphold_state_token)

    # move right to `verification_done`
    url = verification_done_publishers_url
    get(url)

    # verify that a state token has been set
    publisher.reload
    assert_not_nil(publisher.uphold_state_token)

    # assert that the state token is included in the uphold authorization url
    endpoint = Rails.application.secrets[:uphold_authorization_endpoint].gsub('<STATE>', publisher.uphold_state_token)
    assert_select("a.btn-primary[href='#{endpoint}']") do |elements|
      assert_equal(1, elements.length, 'A link with the correct href to Uphold.com is present')
      assert_equal(elements[0].inner_text, 'Connect with Uphold', 'Link text matches expectations')
    end
  end

  test "after redirection back from uphold a publisher's authorization_token is set and finished page is shown" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
    end
    publisher = Publisher.order(created_at: :asc).last
    url = publisher_url(publisher, token: publisher.authentication_token)
    get(url)
    follow_redirect!

    uphold_state_token = SecureRandom.hex(64)
    publisher.uphold_state_token = uphold_state_token

    publisher.verified = true
    publisher.save!

    url = uphold_verified_publishers_path
    get(url, params: { code: 'ebb18043eb2e106fccb9d13d82bec119d8cd016c', state: uphold_state_token })
    assert(200, response.status)

    publisher.reload
    # verify that the uphold_state_token has been cleared
    assert_nil(publisher.uphold_state_token)

    # verify that the authorization token has been set
    assert_not_nil(publisher.uphold_code)
    assert_equal('ebb18043eb2e106fccb9d13d82bec119d8cd016c', publisher.uphold_code)

    # verify that the finished_header was displayed
    assert_match(I18n.t('publishers.finished_header'), response.body)
  end

  test "after redirection back from uphold, a missing publisher's `uphold_state_token` redirects back to verification_done" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
    end
    publisher = Publisher.order(created_at: :asc).last
    url = publisher_url(publisher, token: publisher.authentication_token)
    get(url)
    follow_redirect!
    publisher.verified = true
    publisher.save!

    url = uphold_verified_publishers_path
    get(url, params: { code: 'ebb18043eb2e106fccb9d13d82bec119d8cd016c' })
    assert_redirected_to '/publishers/verification_done'

    # Check that failure message is displayed
    follow_redirect!
    assert_match(I18n.t('publishers.verification_uphold_state_token_does_not_match'), response.body)
  end

  test "after redirection back from uphold, a mismatched publisher's `uphold_state_token` redirects back to verification_done" do
    perform_enqueued_jobs do
      post(publishers_path, params: PUBLISHER_PARAMS)
    end
    publisher = Publisher.order(created_at: :asc).last
    url = publisher_url(publisher, token: publisher.authentication_token)
    get(url)
    follow_redirect!

    uphold_state_token = SecureRandom.hex(64)
    publisher.uphold_state_token = uphold_state_token

    publisher.verified = true
    publisher.save!

    spoofed_uphold_state_token = SecureRandom.hex(64)
    url = uphold_verified_publishers_path
    get(url, params: { code: 'ebb18043eb2e106fccb9d13d82bec119d8cd016c', state: spoofed_uphold_state_token })
    assert_redirected_to '/publishers/verification_done'

    # Check that failure message is displayed
    follow_redirect!
    assert_match(I18n.t('publishers.verification_uphold_state_token_does_not_match'), response.body)
  end
end
