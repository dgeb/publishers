module Publishers
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      publisher = current_publisher
      oauth_response = request.env['omniauth.auth']

      if publisher
        if publisher.brave_publisher_id.present?
          raise 'Google OAuth2 Error: Publishers can not be associated with both a brave_publisher_id and a Google account.'
        elsif publisher.provider
          raise 'Google OAuth2 Error: Provider has already been set for Publisher.'
        elsif publisher.provider_user_id
          raise 'Google OAuth2 Error: UID has already been set for Publisher.'
        end
        publisher.provider = oauth_response.provider
        publisher.provider_user_id = oauth_response.uid
        publisher.verified = true
      else
        publisher = Publisher.where(provider: oauth_response.provider, provider_user_id: oauth_response.uid).first
        unless publisher
          redirect_to('/', notice: I18n.t("youtube.account_not_found"))
          return
        end
      end

      session['google_oauth2_credentials_token'] = oauth_response.credentials.token

      # TODO - store required data from response

      publisher.save!

      unless current_publisher
        sign_in(:publisher, publisher)
      end

      redirect_to youtube_channels_publishers_path

    rescue => e
      require "sentry-raven"
      Raven.capture_exception(e)
      sign_out(current_publisher)
      redirect_to '/', error: t('youtube.oauth_error')
    end
  end
end
