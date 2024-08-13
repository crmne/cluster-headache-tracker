class ChartsController < ApplicationController
  def index
    @headache_logs = current_user.headache_logs.order(:start_time)

    @intensity_data = @headache_logs.map { |log| { x: log.start_time, y: log.intensity } }

    @trigger_data = process_trigger_data(@headache_logs)
  end

  private

  def process_trigger_data(logs)
    trigger_counts = Hash.new(0)
    logs.each do |log|
      triggers = log.triggers.to_s.split(",").map(&:strip)
      triggers.each { |trigger| trigger_counts[trigger] += 1 unless trigger.blank? }
    end

    trigger_counts.sort_by { |_, count| -count }.first(5).to_h
  end
end
