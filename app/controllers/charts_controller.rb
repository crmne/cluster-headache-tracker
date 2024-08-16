class ChartsController < ApplicationController
  def index
    @headache_logs = current_user.headache_logs.order(:start_time)
    apply_filters

    @intensity_data = @headache_logs.map { |log| { x: log.start_time, y: log.intensity } }

    @trigger_data = process_trigger_data(@headache_logs)
    @medication_data = process_medication_data(@headache_logs)
  end

  private

  def apply_filters
    if params[:start_date].present?
      @headache_logs = @headache_logs.where("start_time >= ?", params[:start_date])
    end
    if params[:end_date].present?
      @headache_logs = @headache_logs.where("start_time <= ?", params[:end_date])
    end
    if params[:triggers].present?
      @headache_logs = @headache_logs.where("triggers ILIKE ?", "%#{params[:triggers]}%")
    end
    if params[:medication].present?
      @headache_logs = @headache_logs.where("medication ILIKE ?", "%#{params[:medication]}%")
    end
  end

  def process_trigger_data(logs)
    trigger_counts = Hash.new(0)
    logs.each do |log|
      triggers = log.triggers.to_s.split(',').map(&:strip)
      triggers.each { |trigger| trigger_counts[trigger] += 1 unless trigger.blank? }
    end

    trigger_counts.sort_by { |_, count| -count }.first(5).to_h
  end

  def process_medication_data(logs)
    medication_counts = Hash.new(0)
    logs.each do |log|
      medications = log.medication.to_s.split('+').map(&:strip).map(&:downcase)
      medications.each { |med| medication_counts[med] += 1 unless med.blank? }
    end

    medication_counts.sort_by { |_, count| -count }.first(5).to_h
  end
end
