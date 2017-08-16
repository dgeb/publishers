module PublishersHelper
  def publisher_can_receive_funds?(publisher)
    publisher.legal_form_completed? && publisher.bitcoin_address.present?
  end

  # balance: Instance of PublisherBalanceGetter::Balance
  def publisher_humanize_balance(publisher)
    if balance = publisher.balance
      number_to_currency(balance.amount)
    else
      I18n.t("publishers.balance_error")
    end
  end

  def publisher_uri(publisher)
    "https://#{publisher.brave_publisher_id}"
  end

  def uphold_authorization_endpoint(publisher)
    Rails.application.secrets[:uphold_authorization_endpoint].gsub('<STATE>', publisher.uphold_state_token)
  end

  def publisher_humanize_verified(publisher)
    if publisher.verified?
      I18n.t("publishers.verified")
    else
      I18n.t("publishers.not_verified")
    end
  end

  def publisher_verification_file_content(publisher)
    PublisherVerificationFileGenerator.new(publisher: publisher).generate_file_content
  end

  def publisher_verification_file_directory(publisher)
    "<span class=\"strong-line\">https:</span>//#{publisher.brave_publisher_id}/.well-known/"
  end

  def publisher_verification_file_url(publisher)
    PublisherVerificationFileGenerator.new(publisher: publisher).generate_url
  end

  def publisher_next_step_path(publisher)
    return verification_publishers_path if !publisher.verified?
    return verification_done_publishers_path if publisher.bitcoin_address.blank?
    return new_publisher_legal_form_path if !publisher.legal_form_completed?

    home_publishers_path
  end

  # NOTE: Be careful! This link logs the publisher a back in.
  def generate_publisher_private_reauth_url(publisher)
    token = PublisherTokenGenerator.new(publisher: publisher).perform
    publisher_url(publisher, token: token)
  end

  def publisher_verification_dns_record(publisher)
    PublisherDnsRecordGenerator.new(publisher: publisher).perform
  end
end
