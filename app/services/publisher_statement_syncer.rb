class PublisherStatementSyncer
  attr_reader :publisher_statement

  def initialize(publisher_statement:)
    @publisher_statement = publisher_statement
  end

  def perform
    if publisher_statement.s3_key.present?
      puts "PublisherStatementSyncer - s3_key already present"
      return
    end

    data = statement_pdf
    if data
      puts 'PublisherStatementSyncer - has data - uploading to s3'
      s3_key = "#{base_s3_key}.pdf.gpg"
      EncryptedS3Store.new.put_object(data: data, key: s3_key)
      publisher_statement.s3_key = s3_key
      publisher_statement.save!
    else
      puts 'PublisherStatementSyncer - no data yet'
    end
  end

  private

  def statement_pdf
    PublisherStatementGetter.new(publisher_statement: @publisher_statement).perform
  end

  def base_s3_key
    @base_s3_key ||= begin
      uuid = SecureRandom.uuid
      "publisher-statements/#{uuid.first(2)}/#{uuid}"
    end
  end
end
