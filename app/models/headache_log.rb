class HeadacheLog < ApplicationRecord
  belongs_to :user
  validates :start_time, :intensity, presence: true
  validates :intensity, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  # Broadcast all changes (create, update, destroy) to the user's channel
  after_create_commit -> { broadcast_create }
  after_update_commit -> { broadcast_update }
  after_destroy_commit -> { broadcast_destroy }

  # filters
  scope :started_after, ->(start_time) { where("start_time >= ?", Date.parse(start_time).beginning_of_day) }
  scope :ended_before, ->(end_time) { where("end_time <= ? OR end_time IS NULL", Date.parse(end_time).end_of_day) }
  scope :with_triggers, ->(triggers) { where("triggers ILIKE ?", "%#{triggers}%") }
  scope :with_medication, ->(medication) { where("medication ILIKE ?", "%#{medication}%") }

  def self.filter_by_params(params)
    headache_logs = all
    headache_logs = headache_logs.started_after(params[:start_time]) if params[:start_time].present?
    headache_logs = headache_logs.ended_before(params[:end_time]) if params[:end_time].present?
    headache_logs = headache_logs.with_triggers(params[:triggers]) if params[:triggers].present?
    headache_logs = headache_logs.with_medication(params[:medication]) if params[:medication].present?
    headache_logs
  end

  private

  def broadcast_create
    # Check if this is the first headache log
    if user.headache_logs.count == 1
      # Replace the entire frame to remove empty state
      broadcast_replace_to [ user, "headache_logs" ], target: "headache_logs",
                                                     partial: "headache_logs/logs_grid",
                                                     locals: { headache_logs: user.headache_logs.order(start_time: :desc) }
    else
      # Just prepend the new log
      broadcast_prepend_to [ user, "headache_logs" ], target: "headache_logs",
                                                     partial: "headache_logs/headache_log",
                                                     locals: { headache_log: self }
    end

    broadcast_update_stats
    broadcast_update_ongoing_headaches
    broadcast_update_charts
  end

  def broadcast_update
    Rails.logger.info "Broadcasting update for headache log #{id}"

    broadcast_replace_to [ user, "headache_logs" ], target: self,
                                                   partial: "headache_logs/headache_log",
                                                   locals: { headache_log: self }

    # Also update the headache log card on charts page if it exists there
    broadcast_replace_to [ user, "charts" ], target: self,
                                            partial: "headache_logs/headache_log",
                                            locals: { headache_log: self }

    broadcast_update_stats
    broadcast_update_ongoing_headaches
    broadcast_update_charts
  end

  def broadcast_destroy
    broadcast_remove_to [ user, "headache_logs" ], target: self

    # Also remove from charts page if viewing it
    broadcast_remove_to [ user, "charts" ], target: self

    # Check if this was the last headache log
    if user.headache_logs.count == 0
      # Replace the entire frame to show empty state
      broadcast_replace_to [ user, "headache_logs" ], target: "headache_logs",
                                                     partial: "headache_logs/logs_grid",
                                                     locals: { headache_logs: user.headache_logs.order(start_time: :desc) }
    end

    broadcast_update_stats
    broadcast_update_ongoing_headaches
    broadcast_update_charts
  end

  def broadcast_update_stats
    # Update stats on index page
    broadcast_replace_to [ user, "headache_logs" ], target: "headache_stats",
                                                   partial: "headache_logs/stats",
                                                   locals: { current_user: user }

    # Also update stats on charts page
    broadcast_replace_to [ user, "charts" ], target: "headache_stats",
                                            partial: "headache_logs/stats",
                                            locals: { current_user: user }
  end

  def broadcast_update_ongoing_headaches
    broadcast_replace_to [ user, "headache_logs" ], target: "ongoing_headaches",
                                                   partial: "headache_logs/ongoing_headaches",
                                                   locals: { current_user: user }

    # Also update ongoing headaches on charts page
    broadcast_replace_to [ user, "charts" ], target: "ongoing_headaches",
                                            partial: "headache_logs/ongoing_headaches",
                                            locals: { current_user: user }

    # Update ongoing headaches on all other pages (new, edit, settings, etc.)
    broadcast_replace_to [ user, "application" ], target: "ongoing_headaches",
                                                 partial: "headache_logs/ongoing_headaches",
                                                 locals: { current_user: user }
  end

  def broadcast_update_charts
    Rails.logger.info "Broadcasting chart update for user #{user.id}"

    # Get all headache logs for the user to recalculate chart data
    headache_logs = user.headache_logs.order(:start_time)

    # Include the ChartDataProcessor module to process chart data
    processor = Object.new.extend(ChartDataProcessor)
    chart_data = processor.process_chart_data(headache_logs)

    # Broadcast to replace the entire charts turbo frame
    broadcast_replace_to [ user, "charts" ],
                        target: "charts",
                        partial: "charts/charts_frame",
                        locals: { headache_logs: headache_logs, chart_data: chart_data }
  end
end
