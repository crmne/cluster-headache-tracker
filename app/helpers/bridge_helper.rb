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

  # TODO: Switch to current_user.widget_status once the quick-log branch lands.
  def widget_status_payload(user = current_user)
    ongoing_attack = user.headache_logs.where(end_time: nil).recent_first.first
    last_attack = user.headache_logs.recent_first.first

    {
      ongoing: ongoing_attack.present?,
      startedAt: ongoing_attack&.start_time&.iso8601,
      lastAttackAt: last_attack&.start_time&.iso8601,
      attackFreeDays: last_attack&.end_time ? (Date.current - last_attack.end_time.to_date).to_i : 0,
      attacksToday: user.headache_logs.today.count,
      locale: I18n.locale.to_s
    }
  end

  private
    def native_bridge_components
      @native_bridge_components ||= request.user_agent.to_s[/bridge-components: \[(.*?)\]/, 1].to_s.split
    end
end
