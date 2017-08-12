# Ask Eyeshade to assign a Publisher a particular bitcoin wallet address.
class PublisherWalletSetter < BaseApiClient
  attr_reader :publisher, :bitcoin_address

  def initialize(publisher:)
    @publisher = publisher
  end

  def perform
    return perform_offline if Rails.application.secrets[:api_eyeshade_offline]
    params = {
      "parameters": {
        "code" => publisher.uphold_code,
      },
      "verificationId" => publisher.id,
    }
    # This raises when response is not 2xx.
    response = connection.put do |request|
      request.body = JSON.dump(params)
      request.headers["Authorization"] = api_authorization_header
      request.headers["Content-Type"] = "application/json"
      request.url("/v2/publishers/#{publisher.brave_publisher_id}/wallet")
    end
  end

  def perform_offline
    Rails.logger.info("PublisherVerifier eyeshade offline; only locally updating Bitcoin address.")
    true
  end

  private

  def api_base_uri
    Rails.application.secrets[:api_eyeshade_base_uri]
  end

  def api_authorization_header
    "Bearer #{Rails.application.secrets[:api_eyeshade_key]}"
  end
end
