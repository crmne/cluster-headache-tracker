require "test_helper"

class PwaManifestTest < ActionDispatch::IntegrationTest
  test "shortcuts open quick log and the current attack" do
    get pwa_manifest_url

    assert_response :success
    shortcuts = response.parsed_body["shortcuts"].index_by { |shortcut| shortcut["url"] }

    assert_equal "Log attack", shortcuts.fetch("/headache_logs/new?quick=1")["name"]
    assert_equal "Current attack", shortcuts.fetch("/current_attack")["name"]
    assert_match %r{shortcuts/current-attack-\h+\.png}, shortcuts.fetch("/current_attack")["icons"].first["src"]
  end
end
