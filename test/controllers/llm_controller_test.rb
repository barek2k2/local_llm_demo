require "test_helper"

class LlmControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get llm_index_url
    assert_response :success
  end
end
