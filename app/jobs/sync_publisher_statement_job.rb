class SyncPublisherStatementJob < ApplicationJob
  queue_as :default

  def perform(publisher_statement_id:)
    publisher_statement = PublisherStatement.find(publisher_statement_id)

    PublisherStatementSyncer.new(publisher_statement: publisher_statement).perform

    publisher_statement.reload
    unless publisher_statement.s3_key.present?
      SyncPublisherStatementJob.set(wait: 5.seconds).perform_later(publisher_statement_id: publisher_statement.id)
    end
  end
end
