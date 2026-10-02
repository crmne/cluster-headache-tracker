module ReportDownload
  extend ActiveSupport::Concern

  private
    # The name and "prepared for" fields are only printed on the PDF; they
    # are never stored.
    def send_report(headache_logs)
      report = headache_logs.report(patient_name: params[:patient_name], prepared_for: params[:prepared_for], filters: report_filters)

      no_store
      send_data report.to_pdf, filename: report.filename, type: :pdf, disposition: :attachment
    end

    def report_filters
      params.slice(*HeadacheLog::Report::FILTERS).permit(*HeadacheLog::Report::FILTERS)
    end
end
