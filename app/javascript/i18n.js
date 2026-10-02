// Translations for Stimulus controllers. The layout renders the js.* keys of the
// current locale into <script id="translations"> and the language and 12h/24h
// preference onto <body>, so they follow every Turbo visit.
//
//   import { t, locale, formatTime } from "i18n"
//   t("charts.intensity.title")
//   t("timer.minutes_ago", { count: 5 })   // picks one/other from the plural forms

export function locale() {
  return document.body?.dataset.locale || document.documentElement.lang || "en"
}

export function hourCycle() {
  return document.body?.dataset.hourCycle || "h12"
}

export function t(key, options = {}) {
  let value = key.split(".").reduce((scope, part) => scope?.[part], translations())

  if (value && typeof value === "object" && "count" in options) {
    value = value[new Intl.PluralRules(locale()).select(options.count)] ?? value.other
  }

  if (typeof value !== "string") return key

  return value.replace(/%\{(\w+)\}/g, (match, name) => name in options ? String(options[name]) : match)
}

export function formatTime(date, options = {}) {
  return new Intl.DateTimeFormat(locale(), { hour: "numeric", minute: "2-digit", hourCycle: hourCycle(), ...options }).format(date)
}

export function formatDate(date, options = { day: "numeric", month: "short", year: "numeric" }) {
  return new Intl.DateTimeFormat(locale(), options).format(date)
}

export function formatNumber(number, options = {}) {
  return new Intl.NumberFormat(locale(), options).format(number)
}

function translations() {
  const element = document.getElementById("translations")

  if (element !== cachedElement) {
    cachedElement = element
    cachedTranslations = element ? JSON.parse(element.textContent) : {}
  }

  return cachedTranslations
}

let cachedElement = null
let cachedTranslations = {}
