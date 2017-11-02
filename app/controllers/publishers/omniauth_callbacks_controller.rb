module Publishers
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      publisher = current_publisher
      oauth_response = request.env['omniauth.auth']

      if publisher
        if publisher.brave_publisher_id.present?
          raise 'Google OAuth2 Error: Publishers can not be associated with both a brave_publisher_id and a Google account.'
        elsif publisher.auth_provider
          raise 'Google OAuth2 Error: Provider has already been set for Publisher.'
        elsif publisher.auth_user_id
          raise 'Google OAuth2 Error: UID has already been set for Publisher.'
        end
        publisher.auth_provider = oauth_response.provider
        publisher.auth_user_id = oauth_response.uid
        publisher.auth_name = oauth_response.dig('info', 'name')
        publisher.auth_email = oauth_response.dig('info', 'email')

        publisher.verified = true

        publisher.save!
      else
        publisher = Publisher.where(auth_provider: oauth_response.provider, auth_user_id: oauth_response.uid).first
        unless publisher
          redirect_to('/', notice: I18n.t("youtube.account_not_found"))
          return
        end
      end

      session['google_oauth2_credentials_token'] = oauth_response.credentials.token

      unless current_publisher
        sign_in(:publisher, publisher)
      end

      redirect_to home_publishers_path

    rescue => e
      require "sentry-raven"
      Raven.capture_exception(e)
      sign_out(current_publisher)
      redirect_to '/', error: t('youtube.oauth_error')
    end
  end
end
