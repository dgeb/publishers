require 'test_helper'

class ExchangeUpholdCodeForAccessTokenJobTest < ActiveJob::TestCase
  test "sets uphold_access_parameters on success" do
    begin
      init_api_uphold_offline_succeeds = Rails.application.secrets[:api_uphold_offline_succeeds]
      # init_api_uphold_offline_fails_bad_code = Rails.application.secrets[:api_uphold_offline_fails_bad_code]
      Rails.application.secrets[:api_uphold_offline_succeeds] = true
      # Rails.application.secrets[:api_uphold_offline_fails_bad_code] = true

      publisher = publishers(:verified)
      publisher.uphold_code = "foo"
      publisher.uphold_access_parameters = nil
      publisher.save!

      ExchangeUpholdCodeForAccessTokenJob.perform_now(brave_publisher_id: publisher.id)
      publisher.reload

      assert_nil publisher.uphold_code
      refute_nil publisher.uphold_access_parameters

    ensure
      Rails.application.secrets[:api_uphold_offline_succeeds] = init_api_uphold_offline_succeeds
      # Rails.application.secrets[:api_uphold_offline_fails_bad_code] = init_api_uphold_offline_fails_bad_code
    end
  end

  test "clears uphold_code on invalid_grant" do
    begin
      init_api_uphold_offline_succeeds = Rails.application.secrets[:api_uphold_offline_succeeds]
      init_api_uphold_offline_fails_bad_code = Rails.application.secrets[:api_uphold_offline_fails_bad_code]
      Rails.application.secrets[:api_uphold_offline_succeeds] = false
      Rails.application.secrets[:api_uphold_offline_fails_bad_code] = true

      publisher = publishers(:verified)
      publisher.uphold_code = "foo"
      publisher.uphold_access_parameters = nil
      publisher.save!

      ExchangeUpholdCodeForAccessTokenJob.perform_now(brave_publisher_id: publisher.id)
      publisher.reload

      assert_nil publisher.uphold_code
      assert_nil publisher.uphold_access_parameters

    ensure
      Rails.application.secrets[:api_uphold_offline_succeeds] = init_api_uphold_offline_succeeds
      Rails.application.secrets[:api_uphold_offline_fails_bad_code] = init_api_uphold_offline_fails_bad_code
    end
  end

  test "preserves uphold_code on other errors" do
    begin
      init_api_uphold_offline_succeeds = Rails.application.secrets[:api_uphold_offline_succeeds]
      init_api_uphold_offline_fails_bad_code = Rails.application.secrets[:api_uphold_offline_fails_bad_code]
      Rails.application.secrets[:api_uphold_offline_succeeds] = false
      Rails.application.secrets[:api_uphold_offline_fails_bad_code] = false

      publisher = publishers(:verified)
      publisher.uphold_code = "foo"
      publisher.uphold_access_parameters = nil
      publisher.save!

      ExchangeUpholdCodeForAccessTokenJob.perform_now(brave_publisher_id: publisher.id)
      publisher.reload

      refute_nil publisher.uphold_code
      assert_nil publisher.uphold_access_parameters

    ensure
      Rails.application.secrets[:api_uphold_offline_succeeds] = init_api_uphold_offline_succeeds
      Rails.application.secrets[:api_uphold_offline_fails_bad_code] = init_api_uphold_offline_fails_bad_code
    end
  end
end
