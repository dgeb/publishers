Rails.application.routes.draw do
  resources :publishers, only: %i(create new show) do
    collection do
      get :create_done
      get :download_verification_file
      get :home
      get :log_in, action: :new_auth_token, as: :new_auth_token
      post :log_in, action: :create_auth_token, as: :create_auth_token
      get :log_out
      get :payment_info, action: :edit_payment_info, as: :edit_payment_info
      patch :payment_info, action: :update_payment_info, as: :update_payment_info
      get :verification
      get :verification_dns_record
      get :verification_done
      get :verification_public_file
      get :uphold_verified
      patch :verify
    end
  end
  devise_for :publishers

  resources :publisher_legal_forms, only: %i(create new show), path: "legal_forms" do
    collection do
      get :after_sign
    end
  end

  resources :static, only: [] do
    collection do
      get :index
    end
  end

  root "static#index"

  namespace :api do
    resources :publishers, format: false, only: [] do
      collection do
        post "/", action: :create, as: :create
        get "/:brave_publisher_id", action: :index_by_brave_publisher_id, constraints: { brave_publisher_id: %r{[^\/]+} }
        post "/:brave_publisher_id/notifications", action: :notify, constraints: { brave_publisher_id: %r{[^\/]+} }
        patch "/:brave_publisher_id/legal_form", action: :update_legal_form, constraints: { brave_publisher_id: %r{[^\/]+} }
      end
    end
  end

  resources :errors, only: [], path: "/" do
    collection do
      get "400", action: :error_400
      get "401", action: :error_401
      get "403", action: :error_403
      get "404", action: :error_404
      get "422", action: :error_422
      get "500", action: :error_500
    end
  end

  require "sidekiq/web"
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Protect against timing attacks: (https://codahale.com/a-lesson-in-timing-attacks/)
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use `secure_compare` to stop length information leaking
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["SIDEKIQ_USERNAME"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"])
    end
  end
  mount Sidekiq::Web, at: "/magic"
end
