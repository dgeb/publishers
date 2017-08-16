class ExchangeUpholdCodeForAccessTokenJob < ApplicationJob
  queue_as :default

  def perform(brave_publisher_id:)
    publisher = Publisher.find(brave_publisher_id)
    parameters = UpholdRequestAccessParameters.new(
        publisher: publisher
    ).perform

    # ToDo: UpholdRequestAccessParameters could raise exceptions which could be used to clear the code
    if parameters
      publisher.uphold_access_parameters = parameters
      # The code acquired from https://uphold.com/authorize is only good for one request and times out in 5 minutes
      # it should now be cleared
      publisher.uphold_code = nil
      publisher.save!
    end
  end
end
