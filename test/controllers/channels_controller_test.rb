# require "test_helper"
# require "shared/mailer_test_helper"
# require "webmock/minitest"
#
# class ChannelsControllerTest < ActionDispatch::IntegrationTest
#   include Devise::Test::IntegrationHelpers
#   include ActionMailer::TestHelper
#   include MailerTestHelper
#   include PublishersHelper
#
#   SIGNUP_PARAMS = {
#       email: "alice@example.com"
#   }
#
#   test "can create a Publisher registration, pending email verification" do
#     assert_difference("Publisher.count") do
#       # Confirm email + Admin notification
#       assert_enqueued_emails(2) do
#         post(publishers_path, params: SIGNUP_PARAMS)
#       end
#     end
#     assert_redirected_to(create_done_publishers_path)
#     publisher = Publisher.order(created_at: :asc).last
#     get(publisher_path(publisher))
#     assert_redirected_to(root_path)
#   end
#
#   test "can't create verified Site Channel with an existing verified Site Chanel with the same brave_publisher_id" do
#     perform_enqueued_jobs do
#       post(publishers_path, params: SIGNUP_PARAMS)
#     end
#     publisher = Publisher.order(created_at: :asc).last
#     url = publisher_url(publisher, token: publisher.authentication_token)
#     get(url)
#     follow_redirect!
#
#     update_params = {
#         publisher: {
#             brave_publisher_id_unnormalized: "verified.org",
#             name: "Alice the Pyramid",
#             phone: "+14159001420"
#         }
#     }
#
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: update_params)
#     end
#
#     assert_select('div.notifications') do |element|
#       assert_match("Another person has already verified that website", element.text)
#     end
#
#     # Now retry with a unique domain
#
#     update_params = {
#         publisher: {
#             brave_publisher_id_unnormalized: "this-one-is-unique.org",
#             name: "Alice the Pyramid",
#             phone: "+14159001420"
#         }
#     }
#
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: update_params)
#     end
#
#     assert_redirected_to verification_choose_method_publishers_path
#   end
#
#   test "a publisher's domain can be updated via an ajax patch" do
#     perform_enqueued_jobs do
#       post(publishers_path, params: SIGNUP_PARAMS)
#     end
#     publisher = Publisher.order(created_at: :asc).last
#     url = publisher_url(publisher, token: publisher.authentication_token)
#     get(url)
#     follow_redirect!
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
#     end
#
#     update_params = {
#         publisher: {
#             brave_publisher_id_unnormalized: "verified.org",
#             name: "Alice the Pyramid",
#             phone: "+14159001420"
#         }
#     }
#
#     url = update_unverified_publishers_path
#
#     perform_enqueued_jobs do
#       patch(url,
#             params: update_params,
#             headers: { 'HTTP_ACCEPT' => "application/json" })
#       assert_response 204
#     end
#
#     publisher.reload
#     assert_equal 'taken', publisher.brave_publisher_id_error_code
#     assert_nil publisher.brave_publisher_id
#     assert_nil publisher.brave_publisher_id_unnormalized
#
#     # Now retry with a unique domain
#
#     update_params = {
#         publisher: {
#             brave_publisher_id_unnormalized: "this-one-is-unique.org",
#             name: "Alice the Pyramid",
#             phone: "+14159001420"
#         }
#     }
#
#     url = update_unverified_publishers_path
#
#     perform_enqueued_jobs do
#       patch(url,
#             params: update_params,
#             headers: { 'HTTP_ACCEPT' => "application/json" })
#       assert_response 204
#     end
#
#     publisher.reload
#     assert_nil publisher.brave_publisher_id_error_code
#     assert_equal 'this-one-is-unique.org', publisher.brave_publisher_id
#     assert_nil publisher.brave_publisher_id_unnormalized
#   end
#
#   test "a publisher's domain can be rechecked for https support after an initial failure" do
#     prev_host_inspector_offline = Rails.application.secrets[:host_inspector_offline]
#     begin
#       Rails.application.secrets[:host_inspector_offline] = false
#
#       perform_enqueued_jobs do
#         post(publishers_path, params: SIGNUP_PARAMS)
#       end
#       publisher = Publisher.order(created_at: :asc).last
#       url = publisher_url(publisher, token: publisher.authentication_token)
#       get(url)
#       follow_redirect!
#       perform_enqueued_jobs do
#         patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
#       end
#
#       publisher.verification_method = "public_file"
#       publisher.save
#
#       update_params = {
#           publisher: {
#               brave_publisher_id_unnormalized: "this-one-is-unique.org",
#               name: "Alice the Pyramid",
#               phone: "+14159001420"
#           }
#       }
#
#       stub_request(:get, "http://this-one-is-unique.org").
#           to_return(status: 200, body: "<html><body><h1>Welcome to mysite</h1></body></html>", headers: {})
#       stub_request(:get, "https://this-one-is-unique.org").
#           to_raise(Errno::ECONNREFUSED.new)
#       stub_request(:get, "https://www.this-one-is-unique.org").
#           to_raise(Errno::ECONNREFUSED.new)
#
#       perform_enqueued_jobs do
#         patch(update_unverified_publishers_path,
#               params: update_params,
#               headers: { 'HTTP_ACCEPT' => "application/json" })
#         assert_response 204
#       end
#
#       publisher.reload
#       assert_nil publisher.brave_publisher_id_error_code
#       assert_equal 'this-one-is-unique.org', publisher.brave_publisher_id
#       assert_nil publisher.brave_publisher_id_unnormalized
#       refute publisher.supports_https
#
#       stub_request(:get, "https://this-one-is-unique.org").
#           to_return(status: 200, body: "<html><body><h1>Welcome to mysite</h1></body></html>", headers: {})
#
#       perform_enqueued_jobs do
#         patch(check_for_https_publishers_path)
#         assert_response 302
#         assert_redirected_to '/publishers/verification_public_file'
#       end
#
#       publisher.reload
#       assert publisher.supports_https
#
#     ensure
#       Rails.application.secrets[:host_inspector_offline] = prev_host_inspector_offline
#     end
#   end
#
#   test "relogin normalizes domain prior to matching" do
#     publisher = publishers(:default)
#     perform_enqueued_jobs do
#       get(new_auth_token_publishers_path)
#       params = { publisher: { brave_publisher_id: "https://default.org", email: "alice@default.org" } }
#       post(create_auth_token_publishers_path, params: params)
#     end
#     email = ActionMailer::Base.deliveries.find do |message|
#       message.to.first == publisher.email
#     end
#     assert_not_nil(email)
#     url = publisher_url(publisher, token: publisher.reload.authentication_token)
#     assert_email_body_matches(matcher: url, email: email)
#   end
#
#   test "a publisher's show_verification_status, pending_email, and name can be updated via an ajax patch" do
#     perform_enqueued_jobs do
#       post(publishers_path, params: SIGNUP_PARAMS)
#     end
#     publisher = Publisher.order(created_at: :asc).last
#     url = publisher_url(publisher, token: publisher.authentication_token)
#     get(url)
#     follow_redirect!
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
#     end
#
#     publisher.show_verification_status = false
#     publisher.verified = true
#     publisher.save!
#
#     assert_equal false, publisher.show_verification_status
#
#     url = publishers_path
#     patch(url,
#           params: { publisher: { show_verification_status: 1, pending_email: 'joeblow@example.com', name: 'Joseph Blow' } },
#           headers: { 'HTTP_ACCEPT' => "application/json" })
#     assert_response 204
#
#     publisher.reload
#     assert_equal true, publisher.show_verification_status
#     assert_equal 'joeblow@example.com', publisher.pending_email
#     assert_equal 'Joseph Blow', publisher.name
#   end
#
#   test "a publisher's domain status can be polled via ajax" do
#     perform_enqueued_jobs do
#       post(publishers_path, params: SIGNUP_PARAMS)
#     end
#     publisher = Publisher.order(created_at: :asc).last
#     url = publisher_url(publisher, token: publisher.authentication_token)
#     get(url)
#     follow_redirect!
#
#     url = domain_status_publishers_path
#
#     # domain has not been set yet
#     get(url, headers: { 'HTTP_ACCEPT' => "application/json" })
#     assert_response 404
#
#     update_params = {
#         publisher: {
#             brave_publisher_id_unnormalized: "pyramid.net",
#             name: "Alice the Pyramid",
#             phone: "+14159001420"
#         }
#     }
#
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: update_params )
#     end
#
#     # domain has been set
#     get(url, headers: { 'HTTP_ACCEPT' => "application/json" })
#     assert_response 200
#     assert_match(
#         '{"brave_publisher_id":"pyramid.net",' +
#             '"next_step":"/publishers/verification_choose_method"}',
#         response.body)
#   end
#
#   test "a publisher's status can be polled via ajax" do
#     perform_enqueued_jobs do
#       post(publishers_path, params: SIGNUP_PARAMS)
#     end
#     publisher = Publisher.order(created_at: :asc).last
#     url = publisher_url(publisher, token: publisher.authentication_token)
#     get(url)
#     follow_redirect!
#     perform_enqueued_jobs do
#       patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
#     end
#
#     publisher.show_verification_status = false
#     publisher.verified = true
#     publisher.save!
#
#     assert_equal false, publisher.show_verification_status
#
#     url = status_publishers_path
#     get(url,
#         headers: { 'HTTP_ACCEPT' => "application/json" })
#
#     assert_response 200
#     assert_match(
#         '{"status":"uphold_unconnected",' +
#             '"status_description":"You need to create a wallet with Uphold to receive contributions from Brave Payments.",' +
#             '"timeout_message":null,' +
#             '"uphold_status":"unconnected",' +
#             '"uphold_status_description":"Not connected to Uphold."}',
#         response.body)
#   end
#
# end
