class EncryptedS3Store < BaseS3Client
  def initialize
    require "gpgme_init"
  end

  # Returns S3::Object
  def put_object(data:, key:)
    bucket.put_object(
      acl: "authenticated-read",
      body: crypto.encrypt(data).read,
      key: key
    )
  end

  def get(key:)
    object = bucket.object(key).get
    str = object.body.read
    cipher = GPGME::Data.new(str)
    crypto.decrypt(cipher).read
  end

  private

  def crypto
    @crypto ||= GPGME::Crypto.new(armor: true)
  end
end
