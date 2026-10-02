module TimelinesHelper
  # Where each dose falls along the attack, as a percentage of its length,
  # so the timeline shows medication -> attack -> relief at a glance. An
  # ongoing attack is drawn up to its latest dose.
  def timeline_dose_markers(headache_log)
    doses = headache_log.medication_doses
    finish = headache_log.end_time || [ doses.map(&:taken_at).max, headache_log.start_time + 1.minute ].max
    length = [ finish - headache_log.start_time, 1.minute.to_f ].max

    doses.map do |dose|
      [ dose, ((dose.taken_at - headache_log.start_time) / length * 100).clamp(0, 100).round(1) ]
    end
  end
end
