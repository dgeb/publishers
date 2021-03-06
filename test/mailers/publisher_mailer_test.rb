require 'test_helper'

class PublisherMailerTest < ActionMailer::TestCase
  test "uphold_account_changed" do
    publisher = publishers(:default)
    email = PublisherMailer.uphold_account_changed(publisher)

    # # Send the email, then test that it got queued
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal [publisher.email], email.to
  end

  test "verified_no_wallet" do
    publisher = publishers(:verified)
    email = PublisherMailer.verified_no_wallet(publisher, nil)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal [publisher.email], email.to
  end

  test "confirm_email_change" do
    publisher = publishers(:completed)
    publisher.pending_email = "alice-pending@verified.com"
    publisher.save

    email = PublisherMailer.confirm_email_change(publisher)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal [publisher.pending_email], email.to
  end

  test "verify_email error is rescued if there is no send address" do
    publisher = publishers(:completed)
    publisher.pending_email = ""
    publisher.email = "alice_verified@default.org"
    publisher.save

    # verify error raised if no pending email
    assert_nothing_raised do
      PublisherMailer.verify_email(publisher).deliver_now
    end

    publisher.pending_email = "alice_new@default.org"
    publisher.save
    
    # verify nothing raised if pending email exists
    assert_nothing_raised do
      PublisherMailer.verify_email(publisher).deliver_now
    end
  end

  test "unverified_domain_reached_threshold" do
    domain = "default.org"
    email_address = "alice@default.org"
    email = PublisherMailer.unverified_domain_reached_threshold(domain, email_address)
    
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal [email_address], email.to

    # verify the domain is in the subject
    assert_match "#{domain}", email.subject
  end

  test "unverified_domain_reached_threshold_internal" do
    domain = "default.org"
    email_address = "alice@default.org"
    email = PublisherMailer.unverified_domain_reached_threshold_internal(domain, email_address)
    
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal ['brave-publishers@localhost.local'], email.from

    # verify the domain is in the subject
    assert_match "#{domain}", email.subject

    # verify email is marked as internal
    assert_match "<Internal>", email.subject
  end

  test "verified_invalid_wallet" do
    publisher = publishers(:uphold_connected)
    email = PublisherMailer.verified_invalid_wallet(publisher, nil)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['brave-publishers@localhost.local'], email.from
    assert_equal [publisher.email], email.to

    # Ensure emails are not delivered if they have never created a wallet
    publisher = publishers(:default)
    email = PublisherMailer.verified_invalid_wallet(publisher, nil)

    assert_emails 0 do
      email.deliver_now
    end
  end

  test "verified_invalid_wallet_internal" do
    publisher = publishers(:uphold_connected)
    email = PublisherMailer.verified_invalid_wallet_internal(publisher, nil)

    assert_emails 1 do
      email.deliver_now
    end
  end

  test "login_email verify_email verification_done and confirm_email_change raise unless token fresh" do
    publisher = publishers(:default)

    publisher.authentication_token = nil
    publisher.authentication_token_expires_at = 1.hour.ago

    assert_raise do PublisherMailer.login_email(publisher).deliver end
    assert_raise do PublisherMailer.verify_email(publisher).deliver end
    assert_raise do PublisherMailer.confirm_email_change(publisher).deliver end
    assert_raise do PublisherMailer.verification_done(publisher.channels.first).deliver end
  end
end
