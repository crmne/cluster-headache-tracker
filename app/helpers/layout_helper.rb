module LayoutHelper
  def static_page?
    current_page?(root_path) ||
    current_page?(faq_path) ||
    current_page?(imprint_path) ||
    current_page?(privacy_policy_path)
  end

  def form_page?
    current_page?(new_headache_log_path) ||
    (controller_name == "headache_logs" && action_name == "edit")
  end

  def native_app_form_page?
    hotwire_native_app? && form_page?
  end
end
