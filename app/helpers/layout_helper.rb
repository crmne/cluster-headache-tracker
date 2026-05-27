module LayoutHelper
  def static_page?
    static_page_paths.include?(request.path)
  end

  def full_width_static_page?
    full_width_static_page_paths.include?(request.path)
  end

  def form_page?
    current_page?(new_headache_log_path) ||
    (controller_name == "headache_logs" && action_name == "edit")
  end

  def native_app_form_page?
    hotwire_native_app? && form_page?
  end

  private
    def static_page_paths
      full_width_static_page_paths + [
        imprint_path,
        privacy_policy_path
      ]
    end

    def full_width_static_page_paths
      [
        root_path,
        faq_path,
        neurologist_path,
        cluster_headache_diary_path,
        cluster_headache_diary_template_path,
        headache_diary_for_neurologist_path,
        cluster_headache_oxygen_documentation_path,
        sample_report_path,
        cluster_headache_app_path,
        open_source_headache_tracker_path
      ]
    end
end
