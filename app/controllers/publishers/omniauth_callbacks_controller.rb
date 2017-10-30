module Publishers
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      publisher = Publisher.from_omniauth(oauth_response)

      if publisher.persisted?
        flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: provider)
        sign_in_and_redirect publisher, event: :authentication
      else
        session["devise.google_data"] = oauth_response.except(:extra)
        params[:error] = :account_not_found
        # do_failure_things
      end
    end
  end
end
