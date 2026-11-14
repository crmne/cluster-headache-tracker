require "test_helper"

# IndexNow checks that we own the site by fetching the key file named in each
# submission (.github/workflows/release.yml), so it must be served as is.
class IndexnowKeyTest < ActionDispatch::IntegrationTest
  KEY = "21af1cc30d799c2065965884eba5cc3f"

  test "serves the IndexNow key file" do
    get "/#{KEY}.txt"

    assert_response :success
    assert_equal KEY, response.body.strip
  end
end
