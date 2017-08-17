require 'test_helper'
require 'webmock/minitest'

class UploadUpholdAccessParametersJobTest < ActiveJob::TestCase
  test "clears uphold_access_parameters on success" do
    publisher = publishers(:verified)
    publisher.uphold_access_parameters = '{"access_token":"abc123","token_type":"bearer"}'
    publisher.save!

    stub_request(:put, /publishers\/#{publisher.brave_publisher_id}\/wallet/)
        .with(body: "{\"parameters\": {\"access_token\":\"abc123\",\"token_type\":\"bearer\"}, \"verificationId\": \"#{publisher.id}\"}")

    UploadUpholdAccessParametersJob.perform_now(publisher_id: publisher.id)

    publisher.reload
    assert publisher.uphold_verified?
  end
end
