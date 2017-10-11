class PublisherStatementS3Getter < BaseS3Client
  S3_SIGNED_URL_TTL = 1.day

  attr_reader :publisher_statement

  def initialize(publisher_statement:)
    @publisher_statement = publisher_statement
  end

  def get_statement_s3_url
    bucket.object(publisher_statement.s3_key).presigned_url(:get, expires_in: S3_SIGNED_URL_TTL)
  end
end
