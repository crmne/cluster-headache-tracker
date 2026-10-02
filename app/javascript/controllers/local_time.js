// The value a datetime-local input expects for the current local time
// (YYYY-MM-DDThh:mm), matching how the rest of the app records times.
export function localDateTimeValue(date = new Date()) {
  const pad = (number) => String(number).padStart(2, "0")

  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}`
}
