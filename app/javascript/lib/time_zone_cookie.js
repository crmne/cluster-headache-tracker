// Tell the server which time zone the browser is in, so day-based stats such
// as attack-free streaks start each day at the patient's local midnight.
const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone

if (timeZone) {
  document.cookie = `time_zone=${encodeURIComponent(timeZone)}; path=/; max-age=31536000; SameSite=Lax`
}
