# Attacks and the doses taken outside them, newest first and grouped by
# day. Doses taken during an attack are shown inside it. Paginated with a
# time cursor so it stays fast however long someone has been tracking.
class Timeline
  PAGE_SIZE = 40

  Day = Data.define(:date, :entries)

  attr_reader :user, :before, :limit

  def initialize(user, before: nil, limit: PAGE_SIZE)
    @user = user
    @before = Time.zone.parse(before.to_s) if before.present?
    @limit = limit
  end

  def days
    entries.group_by { |entry| time_of(entry).to_date }.map { |date, entries| Day.new(date: date, entries: entries) }
  end

  def entries
    @entries ||= (headache_logs + standalone_doses).sort_by { |entry| time_of(entry) }.reverse.first(limit)
  end

  def next_before
    if entries.size == limit
      time_of(entries.last).iso8601(6)
    end
  end

  private
    def headache_logs
      page(user.headache_logs.includes(medication_doses: :medication), :start_time)
    end

    def standalone_doses
      page(user.medication_doses.standalone.includes(:medication), :taken_at)
    end

    def page(scope, column)
      scope = scope.where(column => ...before) if before
      scope.order(column => :desc).limit(limit).to_a
    end

    def time_of(entry)
      entry.is_a?(HeadacheLog) ? entry.start_time : entry.taken_at
    end
end
