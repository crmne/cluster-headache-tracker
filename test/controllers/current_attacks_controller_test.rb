require "test_helper"

class CurrentAttacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "show offers to start an attack when nothing is ongoing" do
    get current_attack_url

    assert_response :success
    assert_select "#start_attack button[name=intensity]", count: 10
    assert_select "#end_attack", count: 0
  end

  test "show offers to end the ongoing attack" do
    headache_logs(:one).update!(end_time: nil)

    get current_attack_url

    assert_response :success
    assert_select "h1", "Attack in progress"
    assert_select "#end_attack button", /End attack now/
    assert_select "#start_attack", count: 0
  end

  test "show fits the native app modal without web navigation" do
    get current_attack_url, headers: { "User-Agent" => "Hotwire Native iOS; ClusterHeadacheTracker/1.0.7;" }

    assert_response :success
    assert_select ".dock", count: 0
    assert_select "a", text: /Back/, count: 0
    assert_select "#start_attack"
  end

  test "show returns the widget status as JSON" do
    attack = headache_logs(:one)
    attack.update!(end_time: nil)

    get current_attack_url(format: :json)

    assert_response :success
    assert_equal({
      "ongoing" => true,
      "startedAt" => attack.start_time.iso8601,
      "lastAttackAt" => attack.start_time.iso8601,
      "attackFreeDays" => 0,
      "attacksToday" => 1,
      "locale" => "en"
    }, response.parsed_body)
  end

  test "show requires a signed in user" do
    sign_out @user

    get current_attack_url(format: :json)

    assert_response :unauthorized
  end

  test "create starts an ongoing attack now" do
    freeze_time do
      assert_difference -> { @user.headache_logs.count } do
        post current_attack_url, params: { intensity: 8 }
      end

      attack = @user.headache_logs.ongoing.sole
      assert_redirected_to current_attack_url
      assert_equal Time.current, attack.start_time
      assert_nil attack.end_time
      assert_equal 8, attack.intensity
    end
  end

  test "create keeps the ongoing attack instead of starting another" do
    headache_logs(:one).update!(end_time: nil)

    assert_no_difference -> { HeadacheLog.count } do
      post current_attack_url, params: { intensity: 8 }
    end

    assert_redirected_to current_attack_url
  end

  test "create rejects an invalid intensity" do
    assert_no_difference -> { HeadacheLog.count } do
      post current_attack_url, params: { intensity: 11 }
    end

    assert_redirected_to current_attack_url
    assert_equal "Choose a pain level from 1 to 10.", flash[:alert]
  end

  test "destroy ends the ongoing attack now" do
    attack = headache_logs(:one)
    attack.update!(end_time: nil)

    freeze_time do
      delete current_attack_url

      assert_redirected_to current_attack_url
      assert_equal "Attack ended.", flash[:notice]
      assert_equal Time.current, attack.reload.end_time
    end
  end

  test "destroy returns to the page the attack was ended from" do
    headache_logs(:one).update!(end_time: nil)

    delete current_attack_url, headers: { "Referer" => headache_logs_url }

    assert_redirected_to headache_logs_url
  end

  test "destroy with nothing ongoing changes nothing" do
    assert_no_changes -> { @user.headache_logs.pluck(:end_time) } do
      delete current_attack_url
    end

    assert_redirected_to current_attack_url
    assert_equal "No attack in progress.", flash[:alert]
  end

  test "destroy leaves other users' attacks untouched" do
    other_attack = headache_logs(:two)
    other_attack.update!(end_time: nil)

    delete current_attack_url

    assert_redirected_to current_attack_url
    assert_nil other_attack.reload.end_time
  end

  test "create leaves other users' attacks untouched" do
    other_attack = headache_logs(:two)
    other_attack.update!(end_time: nil)

    assert_difference -> { @user.headache_logs.count } do
      post current_attack_url, params: { intensity: 6 }
    end

    assert_nil other_attack.reload.end_time
    assert_equal 1, users(:two).headache_logs.ongoing.count
  end
end
