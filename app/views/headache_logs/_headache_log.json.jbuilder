json.extract! headache_log, :id, :start_time, :end_time, :intensity, :notes, :user_id, :created_at, :updated_at
json.url headache_log_url(headache_log, format: :json)
