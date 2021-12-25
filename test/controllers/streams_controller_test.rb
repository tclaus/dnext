require "test_helper"

class StreamsControllerTest < ActionDispatch::IntegrationTest
  test "should get public" do
    get streams_public_url
    assert_response :success
  end
end
