require "csv"

# Convert times to the application time zone when exporting
CSV::Converters[:timezone] = lambda do |field, info|
  if info.header == "start_time" || info.header == "end_time"
    Time.parse(field).in_time_zone
  else
    field
  end
end

# Parse times as UTC when importing
CSV::Converters[:utc] = lambda do |field, info|
  if info.header == "start_time" || info.header == "end_time"
    Time.parse(field).utc
  else
    field
  end
end
