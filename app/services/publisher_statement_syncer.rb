class PublisherStatementSyncer
  attr_reader :publisher_statement

  def initialize(publisher_statement:)
    @publisher_statement = publisher_statement
  end

  def perform
    s3_key = "#{base_s3_key}.pdf.gpg"
    EncryptedS3Store.new.put_object(data: statement_pdf, key: s3_key)
    publisher_statement.s3_key = s3_key
    publisher_statement.save!
  end

  def s3_url
    s3_getter.get_s3_url
  end

  private

  def statement_pdf
    getter = PublisherStatementGetter.new(publisher_statement: @publisher_statement)
    getter.perform
  end

  def base_s3_key
    @base_s3_key ||= begin
      uuid = SecureRandom.uuid
      "publisher-statements/#{uuid.first(2)}/#{uuid}"
    end
  end

  def s3_getter
    @s3_getter ||= PublisherStatementS3Getter.new(publisher_statement: @publisher_statement)
  end
end
