module BridgeHelper
  def bridge_component_supported?(component)
    native_bridge_components.include?(component)
  end

  def bridge_body_attributes
    if hotwire_native_app?
      tag.attributes data: {
        controller: "bridge--theme bridge--alert",
        bridge__alert_confirm_value: t("bridge.alert.confirm"),
        bridge__alert_destructive_confirm_value: t("bridge.alert.destructive_confirm"),
        bridge__alert_dismiss_value: t("bridge.alert.dismiss")
      }
    end
  end

  def flash_haptic_feedback(type)
    case type.to_s
    when "notice", "info" then "success"
    when "alert" then "warning"
    when "error" then "error"
    end
  end

  # Only on a calm visit: nothing just happened (no flash) and no other modal competes for attention.
  def show_review_prompt?
    bridge_component_supported?("review-prompt") && flash.empty? && !show_mobile_app_update_modal? &&
      current_user.welcome_seen_at? && ChangelogEntry.current.seen_by?(current_user) &&
      current_user.review_prompt_due?
  end

  private
    def native_bridge_components
      @native_bridge_components ||= request.user_agent.to_s[/bridge-components: \[(.*?)\]/, 1].to_s.split
    end
end
