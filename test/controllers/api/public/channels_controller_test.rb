require "test_helper"
require "shared/mailer_test_helper"

class Api::Public::ChannelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'a site not in the system' do
    get "/api/public/channels/identity?publisher=brave.com",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    assert_equal 200, response.status
  end

  test 'a site not yet verified' do
    channel = channels(:small_media_group_to_verify)
    get "/api/public/channels/identity?publisher=#{channel.details.brave_publisher_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)
    assert_equal 200, response.status
    assert_equal channel.details.brave_publisher_id, response_body["SLD"]
    assert_equal ""         , response_body["RLD"]
    assert_equal ""         , response_body["QLD"]
    assert_equal channel.details.brave_publisher_id, response_body["URL"]
    assert       response_body['properties']['timestamp'] != nil
  end

  test 'a site that is marked for exclude' do
    channel = channels(:verified_exclude)
    get "/api/public/channels/identity?publisher=#{channel.details.brave_publisher_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)
    assert_equal 200, response.status
    assert_equal channel.details.brave_publisher_id , response_body["SLD"]
    assert_equal ""                                 , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['verified']
    assert_equal true                               , response_body['properties']['exclude']
  end

  test 'a site that is verified' do
    channel = channels(:verified)
    get "/api/public/channels/identity?publisher=#{channel.details.brave_publisher_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal channel.details.brave_publisher_id , response_body["SLD"]
    assert_equal ""                                 , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['verified']
  end

  test 'an invalid url that was never registered with Publishers' do
    random_url = "foo.amazon.com"
    get "/api/public/channels/identity?publisher=#{random_url}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 'amazon.com'                       , response_body["SLD"]
    assert_equal 'amazon.com'                       , response_body["publisher"]
    assert_equal "foo"                              , response_body["RLD"]
    assert_equal "foo"                              , response_body["QLD"]
    assert_nil                                        response_body['properties']
  end

  test 'a site that was never registered with Publishers' do
    random_url = "shouldfail.github.io"
    get "/api/public/channels/identity?publisher=#{random_url}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal random_url                         , response_body["SLD"]
    assert_equal random_url                         , response_body["publisher"]
    assert_equal ""                                 , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_nil                                        response_body['properties']
  end

  test 'an excluded site that was never registered with Publishers' do
    file_path = Rails.root.join("test/config/excluded_site_channels.yml")
    excluded_url = Set.new(YAML.load_file(file_path)).first
    get "/api/public/channels/identity?publisher=#{excluded_url}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal excluded_url                       , response_body["SLD"]
    assert_equal excluded_url                       , response_body["publisher"]
    assert_equal ""                                 , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['exclude']
    assert_equal excluded_url                       , response_body['URL']
  end

  test 'a subdomain of an excluded domain that was never registered with Publishers' do
    subdomain = 'foo'
    file_path = Rails.root.join("test/config/excluded_site_channels.yml")
    excluded_url = Set.new(YAML.load_file(file_path)).first
    get "/api/public/channels/identity?publisher=#{subdomain}.#{excluded_url}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal excluded_url                       , response_body["SLD"]
    assert_equal excluded_url                       , response_body["publisher"]
    assert_equal subdomain                          , response_body["RLD"]
    assert_equal subdomain                          , response_body["QLD"]
    assert_equal true                               , response_body['properties']['exclude']
    assert_equal "#{subdomain}.#{excluded_url}"     , response_body['URL']
  end

  test 'a youtube channel' do
    not_present_channel = 'ipwnnoobs'
    get "/api/public/channels/identity?publisher=youtube%23channel%3A#{not_present_channel}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                      , response.status
    assert_equal "youtube#channel:#{not_present_channel}" , response_body["publisher"]
    assert_equal 'provider'                               , response_body['publisherType']
    assert_equal Channel::YOUTUBE                         , response_body['providerName']
    assert_equal 'channel'                                , response_body['providerSuffix']
    assert_equal not_present_channel                      , response_body['providerValue']
    assert_equal "youtube#channel"                        , response_body["TLD"]
    assert_equal "youtube#channel:#{not_present_channel}" , response_body["SLD"]
    assert_equal not_present_channel                      , response_body["RLD"]
    assert_equal ""                                       , response_body["QLD"]
    assert_nil                                              response_body['properties']

    channel = channels(:youtube_new)
    get "/api/public/channels/identity?publisher=youtube%23channel%3A#{channel.details.youtube_channel_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                , response.status
    assert_equal 'provider'                         , response_body['publisherType']
    assert_equal 'youtube'                          , response_body['providerName']
    assert_equal 'channel'                          , response_body['providerSuffix']
    assert_equal channel.details.youtube_channel_id , response_body['providerValue']
    assert_match /youtube.com\/channel\/#{channel.details.youtube_channel_id}/, response_body["URL"]
    assert_equal "youtube#channel"                  , response_body["TLD"]
    assert_equal "youtube#channel:#{channel.details.youtube_channel_id}", response_body["SLD"]
    assert_equal channel.details.youtube_channel_id , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['verified']
    assert_equal (channel.updated_at.to_i << 32).to_s, response_body['properties']['timestamp']

    channel.update(verified: false)
    get "/api/public/channels/identity?publisher=youtube%23channel%3A#{channel.details.youtube_channel_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                , response.status
    assert_equal 'provider'                         , response_body['publisherType']
    assert_equal 'youtube'                          , response_body['providerName']
    assert_equal 'channel'                          , response_body['providerSuffix']
    assert_equal channel.details.youtube_channel_id , response_body['providerValue']
    assert_match /youtube.com\/channel\/#{channel.details.youtube_channel_id}/, response_body["URL"]
    assert_equal "youtube#channel"                  , response_body["TLD"]
    assert_equal "youtube#channel:#{channel.details.youtube_channel_id}", response_body["SLD"]
    assert_equal channel.details.youtube_channel_id , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert       response_body['properties']['timestamp'] != nil
  end

  test 'a twitch channel' do
    not_present_channel = 'ipwnnoobs'
    get "/api/public/channels/identity?publisher=twitch%23author%3A#{not_present_channel}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                    , response.status
    assert_equal "twitch#author:#{not_present_channel}" , response_body["publisher"]
    assert_equal 'provider'                             , response_body['publisherType']
    assert_equal Channel::TWITCH                        , response_body['providerName']
    assert_equal 'author'                               , response_body['providerSuffix']
    assert_equal not_present_channel                    , response_body['providerValue']
    assert_equal "twitch#author"                        , response_body["TLD"]
    assert_equal "twitch#author:#{not_present_channel}" , response_body["SLD"]
    assert_equal not_present_channel                    , response_body["RLD"]
    assert_equal ""                                     , response_body["QLD"]
    assert_nil                                            response_body['properties']

    channel = channels(:twitch_verified)
    get "/api/public/channels/identity?publisher=twitch%23author%3A#{channel.details.twitch_channel_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                , response.status
    assert_equal 'provider'                         , response_body['publisherType']
    assert_equal 'twitch'                           , response_body['providerName']
    assert_equal 'author'                           , response_body['providerSuffix']
    assert_equal channel.details.twitch_channel_id , response_body['providerValue']
    assert_equal "twitch#author"                    , response_body["TLD"]
    assert_equal "twitch#author:#{channel.details.twitch_channel_id}", response_body["SLD"]
    assert_equal channel.details.twitch_channel_id , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['verified']
    assert_equal (channel.updated_at.to_i << 32).to_s, response_body['properties']['timestamp']

    get "/api/public/channels/identity?publisher=twitch%23author%3A#{channel.details.name}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                , response.status
    assert_equal 'provider'                         , response_body['publisherType']
    assert_equal 'twitch'                           , response_body['providerName']
    assert_equal 'author'                           , response_body['providerSuffix']
    assert_equal channel.details.name               , response_body['providerValue']
    assert_equal "twitch#author"                    , response_body["TLD"]
    assert_equal "twitch#author:#{channel.details.name}", response_body["SLD"]
    assert_equal channel.details.name               , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert_equal true                               , response_body['properties']['verified']
    assert_equal (channel.updated_at.to_i << 32).to_s, response_body['properties']['timestamp']

    channel.update(verified: false)
    get "/api/public/channels/identity?publisher=twitch%23author%3A#{channel.details.twitch_channel_id}",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_equal 200                                , response.status
    assert_equal 'provider'                         , response_body['publisherType']
    assert_equal 'twitch'                           , response_body['providerName']
    assert_equal 'author'                           , response_body['providerSuffix']
    assert_equal channel.details.twitch_channel_id , response_body['providerValue']
    assert_equal "twitch#author"                    , response_body["TLD"]
    assert_equal "twitch#author:#{channel.details.twitch_channel_id}", response_body["SLD"]
    assert_equal channel.details.twitch_channel_id , response_body["RLD"]
    assert_equal ""                                 , response_body["QLD"]
    assert       response_body['properties']['timestamp'] != nil
  end

  test 'last updated channel' do
    channel = channels(:small_media_group_to_verify)
    get "/api/public/channels/timestamp",
        headers: { "HTTP_AUTHORIZATION" => "Token token=fake_api_auth_token" }
    response_body = JSON.parse(response.body)

    assert_operator (channel.updated_at.to_i << 32).to_s, :<=, response_body['timestamp']
  end
end
