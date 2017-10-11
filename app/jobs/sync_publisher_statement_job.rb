class SyncPublisherStatementJob < ApplicationJob
  queue_as :default

  def perform(publisher_statement_id:)
    publisher_statement = PublisherStatement.find(publisher_statement_id)

    PublisherStatementSyncer.new(publisher_statement: publisher_statement).perform
  end
end
