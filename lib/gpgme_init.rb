require "gpgme"

# GPG is used to encrypt statements when uploading to S3.

GPGME::Key.import(ENV["GPG_PRIVATE_KEY"])
import_result = GPGME::Key.import(ENV["GPG_PUBLIC_KEY"])
GPG_PUBKEY_RECIPIENT = GPGME::Key.get(import_result.imports.first.fpr).email.freeze
