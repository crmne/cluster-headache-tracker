import { Controller } from "@hotwired/stimulus"
import {
  Chart,
  TimeScale,
  LinearScale,
  LogarithmicScale,
  PointElement,
  LineElement,
  LineController,
  ScatterController,
  PieController,
  BarController,
  BarElement,
  ArcElement,
  Legend,
  Title,
  Tooltip,
  CategoryScale
} from "chart.js"
import "chartjs-adapter-date-fns"
import { t, formatDate, formatNumber, formatTime } from "i18n"

Chart.register(
  TimeScale,
  LinearScale,
  LogarithmicScale,
  PointElement,
  LineElement,
  LineController,
  ScatterController,
  PieController,
  BarController,
  BarElement,
  ArcElement,
  Legend,
  Title,
  Tooltip,
  CategoryScale
)

function formatDuration(value, unitDisplay = 'narrow') {
  if (value < 1) {
    return formatNumber(Math.round(value * 60), { style: 'unit', unit: 'minute', unitDisplay })
  } else if (value < 24) {
    return formatNumber(value, { style: 'unit', unit: 'hour', unitDisplay, maximumFractionDigits: 1 })
  } else {
    return formatNumber(value / 24, { style: 'unit', unit: 'day', unitDisplay, maximumFractionDigits: 1 })
  }
}

function formatDurationLong(hours) {
  return formatDuration(hours, 'long')
}

function formatDay(value) {
  return formatDate(new Date(value), { day: 'numeric', month: 'short' })
}

function formatFullDay(value) {
  return formatDate(new Date(value))
}

function formatHourRange(startHour) {
  const start = new Date(2000, 0, 1, startHour, 0)
  const end = new Date(2000, 0, 1, startHour + 1, 59)
  return `${formatTime(start)} – ${formatTime(end)}`
}

// Localized day ticks and tooltip titles for the date-based charts
const timeAxis = {
  type: 'time',
  time: { unit: 'day' },
  ticks: { callback: formatDay }
}

const dayTooltipTitle = items => items.length ? formatFullDay(items[0].parsed.x) : ''

// Connects to data-controller="charts"
export default class extends Controller {
  static targets = [
    "intensityCanvas",
    "triggerCanvas",
    "medicationCanvas",
    "hourlyCanvas",
    "attacksPerDayCanvas",
    "durationCanvas",
    "pressureCanvas",
    "pressureChangeCanvas",
    "adherenceCanvas",
    "container"
  ]

  static values = {
    intensity: Array,
    trigger: Object,
    medication: Object,
    hourly: Array,
    attacksPerDay: Array,
    duration: Array,
    pressure: Array,
    pressureChange: Array,
    pressureLabels: Object,
    medicationColors: Object,
    adherence: Array,
    adherenceLabels: Object
  }

  initialize() {
    this.charts = {}
  }

  disconnect() {
    cancelAnimationFrame(this.pendingFrame)
    Object.values(this.charts).forEach(chart => chart.destroy())
    this.charts = {}
  }

  // Stimulus fires these once on connect and again whenever a value changes
  intensityValueChanged() {
    this.initializeAllCharts()
  }

  triggerValueChanged() {
    this.initializeAllCharts()
  }

  medicationValueChanged() {
    this.initializeAllCharts()
  }

  hourlyValueChanged() {
    this.initializeAllCharts()
  }

  attacksPerDayValueChanged() {
    this.initializeAllCharts()
  }

  durationValueChanged() {
    this.initializeAllCharts()
  }

  pressureValueChanged() {
    this.initializeAllCharts()
  }

  pressureChangeValueChanged() {
    this.initializeAllCharts()
  }

  adherenceValueChanged() {
    this.initializeAllCharts()
  }

  initializeAllCharts() {
    this.containerTargets.forEach(container => container.classList.add('loading'))

    // Coalesce repeated value changes into a single draw on the next frame
    cancelAnimationFrame(this.pendingFrame)
    this.pendingFrame = requestAnimationFrame(() => {
      try {
        this.initializeIntensityChart()
        this.initializeTriggerChart()
        this.initializeMedicationChart()
        this.initializeHourlyChart()
        this.initializeAttacksPerDayChart()
        this.initializeDurationChart()
        this.initializePressureChart()
        this.initializePressureChangeChart()
        this.initializeAdherenceChart()
      } catch (error) {
        console.error('Error initializing charts:', error)
      } finally {
        this.containerTargets.forEach(container => container.classList.remove('loading'))
      }
    })
  }

  initializeIntensityChart() {
    if (!this.hasIntensityCanvasTarget || this.intensityValue.length === 0) return

    // One dot per attack. A line would join attacks across remission and imply
    // pain levels for weeks with no attacks at all.
    this.drawChart('intensity', this.intensityCanvasTarget, {
      type: 'scatter',
      data: {
        datasets: [{
          label: t('charts.intensity.label'),
          data: this.intensityValue,
          borderColor: 'rgb(13, 148, 136)',
          backgroundColor: 'rgba(13, 148, 136, 0.5)',
          pointRadius: 5,
          pointHoverRadius: 8
        }]
      },
      options: {
        scales: {
          x: timeAxis,
          y: {
            // Half a step of room above 10 and below 1 so dots at the extremes aren't clipped.
            min: 0.5,
            max: 10.5,
            afterBuildTicks: axis => { axis.ticks = Array.from({ length: 10 }, (_, index) => ({ value: index + 1 })) }
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: dayTooltipTitle,
              label: context => t('charts.duration.tooltip.intensity', { intensity: context.parsed.y })
            }
          }
        }
      }
    })
  }

  initializeTriggerChart() {
    if (!this.hasTriggerCanvasTarget) return

    this.drawPieChart('trigger', this.triggerCanvasTarget, t('charts.triggers.title'), this.triggerValue)
  }

  initializeMedicationChart() {
    if (!this.hasMedicationCanvasTarget) return

    this.drawPieChart('medication', this.medicationCanvasTarget, t('charts.medications.title'), this.medicationValue, this.medicationColorsValue)
  }

  drawPieChart(key, canvas, title, data, colors = {}) {
    if (Object.keys(data).length === 0) return

    const palette = [
      'rgb(255, 99, 132)',
      'rgb(54, 162, 235)',
      'rgb(255, 205, 86)',
      'rgb(75, 192, 192)',
      'rgb(153, 102, 255)'
    ]

    this.drawChart(key, canvas, {
      type: 'pie',
      data: {
        labels: Object.keys(data),
        datasets: [{
          data: Object.values(data),
          backgroundColor: Object.keys(data).map((label, index) => colors[label] || palette[index % palette.length])
        }]
      },
      options: {
        plugins: {
          legend: {
            position: 'top',
          },
          title: {
            display: true,
            text: title
          }
        }
      }
    })
  }

  initializeHourlyChart() {
    const hourlyData = this.hourlyValue
    if (!this.hasHourlyCanvasTarget || hourlyData.length === 0) return

    this.drawChart('hourly', this.hourlyCanvasTarget, {
      type: 'bar',
      data: {
        labels: hourlyData.map(d => formatHourRange(d.start_hour)),
        datasets: [
          {
            label: t('charts.hourly.frequency'),
            data: hourlyData.map(d => d.frequency),
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            yAxisID: 'y-frequency',
          },
          {
            label: t('charts.hourly.average_intensity_short'),
            data: hourlyData.map(d => d.avg_intensity),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            yAxisID: 'y-intensity',
          }
        ]
      },
      options: {
        scales: {
          x: {
            type: 'category',
            title: {
              display: true,
              text: t('charts.hourly.time_of_day')
            }
          },
          'y-frequency': {
            type: 'linear',
            position: 'left',
            title: {
              display: true,
              text: t('charts.hourly.frequency')
            },
            beginAtZero: true
          },
          'y-intensity': {
            type: 'linear',
            position: 'right',
            title: {
              display: true,
              text: t('charts.hourly.average_intensity')
            },
            beginAtZero: true,
            max: 10
          }
        },
        plugins: {
          title: {
            display: true,
            text: t('charts.hourly.title')
          }
        }
      }
    })
  }

  initializeAttacksPerDayChart() {
    if (!this.hasAttacksPerDayCanvasTarget || this.attacksPerDayValue.length === 0) return

    this.drawChart('attacksPerDay', this.attacksPerDayCanvasTarget, {
      type: 'bar',
      data: {
        datasets: [{
          label: t('charts.attacks_per_day.label'),
          data: this.attacksPerDayValue,
          backgroundColor: 'rgba(54, 162, 235, 0.6)',
          borderColor: 'rgb(54, 162, 235)',
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          x: {
            ...timeAxis,
            title: {
              display: true,
              text: t('charts.date')
            }
          },
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: t('charts.attacks_per_day.label')
            },
            ticks: {
              stepSize: 1
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          title: {
            display: true,
            text: t('charts.attacks_per_day.title')
          },
          tooltip: {
            callbacks: { title: dayTooltipTitle }
          }
        }
      }
    })
  }

  initializeDurationChart() {
    if (!this.hasDurationCanvasTarget || this.durationValue.length === 0) return

    const validData = this.durationValue.filter(d => d && d.y >= 0)  // Allow 0 duration
    if (validData.length === 0) {
      console.warn('No valid duration data after filtering')
      return
    }

    const maxDuration = Math.max(...validData.map(d => d.y))

    this.drawChart('duration', this.durationCanvasTarget, {
      type: 'scatter',
      data: {
        datasets: [{
          label: t('charts.duration.label'),
          data: validData,
          borderColor: 'rgb(147, 51, 234)',
          backgroundColor: 'rgba(147, 51, 234, 0.5)',
          pointRadius: 6,
          pointHoverRadius: 8,
        }]
      },
      options: {
        scales: {
          x: {
            ...timeAxis,
            ticks: { callback: formatFullDay },
            title: {
              display: true,
              text: t('charts.date')
            }
          },
          y: {
            type: maxDuration > 1 ? 'logarithmic' : 'linear',  // Use linear for small durations
            title: {
              display: true,
              text: t('charts.duration.axis')
            },
            min: 0,  // Allow 0 on the scale
            suggestedMax: maxDuration > 0 ? maxDuration * 1.1 : 1,
            ticks: {
              callback: value => formatDuration(value),
              autoSkip: true,
              maxTicksLimit: 8
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                const duration = context.raw.y
                const intensity = context.raw.intensity
                return [
                  t('charts.duration.tooltip.date', { date: formatFullDay(context.raw.x) }),
                  t('charts.duration.tooltip.duration', { duration: formatDurationLong(duration) }),
                  t('charts.duration.tooltip.intensity', { intensity })
                ]
              }
            }
          }
        }
      }
    })
  }

  initializePressureChart() {
    const pressureData = this.pressureValue
    if (!this.hasPressureCanvasTarget || pressureData.length === 0) return

    const labels = this.pressureLabelsValue

    this.drawChart('pressure', this.pressureCanvasTarget, {
      type: 'bar',
      data: {
        labels: pressureData.map(d => d.label),
        datasets: [
          {
            label: labels.frequency,
            data: pressureData.map(d => d.frequency),
            backgroundColor: 'rgba(54, 162, 235, 0.6)',
            yAxisID: 'y-frequency'
          },
          {
            label: labels.averageIntensity,
            data: pressureData.map(d => d.avg_intensity),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            yAxisID: 'y-intensity'
          }
        ]
      },
      options: {
        scales: {
          x: {
            type: 'category',
            title: {
              display: true,
              text: labels.pressureAxis
            }
          },
          'y-frequency': {
            type: 'linear',
            position: 'left',
            title: {
              display: true,
              text: labels.frequency
            },
            beginAtZero: true,
            ticks: {
              stepSize: 1
            }
          },
          'y-intensity': {
            type: 'linear',
            position: 'right',
            title: {
              display: true,
              text: labels.averageIntensity
            },
            beginAtZero: true,
            max: 10
          }
        },
        plugins: {
          title: {
            display: true,
            text: labels.byPressureTitle
          }
        }
      }
    })
  }

  initializePressureChangeChart() {
    if (!this.hasPressureChangeCanvasTarget || this.pressureChangeValue.length === 0) return

    const labels = this.pressureLabelsValue
    const fill = (template, value) => template.replace('%{value}', value)

    this.drawChart('pressureChange', this.pressureChangeCanvasTarget, {
      type: 'bar',
      data: {
        datasets: [{
          label: labels.changeDataset,
          data: this.pressureChangeValue,
          backgroundColor: this.pressureChangeValue.map(d => d.y < 0 ? 'rgba(54, 162, 235, 0.7)' : 'rgba(255, 159, 64, 0.7)'),
          barThickness: 8
        }]
      },
      options: {
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'day'
            },
            title: {
              display: true,
              text: labels.dateAxis
            }
          },
          y: {
            title: {
              display: true,
              text: labels.changeAxis
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const reading = context.raw
                const change = reading.y > 0 ? `+${reading.y}` : `${reading.y}`

                return [
                  fill(labels.changeTooltip, change),
                  fill(labels.pressureTooltip, reading.pressure),
                  fill(labels.hoursTooltip, reading.hours),
                  fill(labels.intensityTooltip, reading.intensity)
                ]
              }
            }
          }
        }
      }
    })
  }

  // Weekly attacks (bars) next to how consistently scheduled preventives
  // were taken that week (line, 0-100%)
  initializeAdherenceChart() {
    if (!this.hasAdherenceCanvasTarget || this.adherenceValue.length === 0) return

    const labels = this.adherenceLabelsValue

    this.drawChart('adherence', this.adherenceCanvasTarget, {
      type: 'bar',
      data: {
        labels: this.adherenceValue.map(week => week.x),
        datasets: [
          {
            type: 'bar',
            label: labels.attacks,
            data: this.adherenceValue.map(week => week.attacks),
            backgroundColor: 'rgba(255, 99, 132, 0.5)',
            yAxisID: 'y-attacks'
          },
          {
            type: 'line',
            label: labels.adherence,
            data: this.adherenceValue.map(week => week.adherence),
            borderColor: 'rgb(14, 165, 233)',
            backgroundColor: 'rgb(14, 165, 233)',
            spanGaps: true,
            tension: 0.2,
            yAxisID: 'y-adherence'
          }
        ]
      },
      options: {
        scales: {
          x: {
            type: 'time',
            time: { unit: 'week' },
            title: { display: true, text: labels.week }
          },
          'y-attacks': {
            type: 'linear',
            position: 'left',
            beginAtZero: true,
            ticks: { stepSize: 1 },
            title: { display: true, text: labels.attacks }
          },
          'y-adherence': {
            type: 'linear',
            position: 'right',
            min: 0,
            max: 100,
            grid: { drawOnChartArea: false },
            ticks: { callback: value => `${value}%` },
            title: { display: true, text: labels.adherence }
          }
        }
      }
    })
  }

  drawChart(key, canvas, config) {
    this.charts[key]?.destroy()
    this.charts[key] = new Chart(canvas.getContext('2d'), {
      ...config,
      options: {
        ...config.options,
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 750, // Consistent animation duration
          easing: 'easeInOutQuart' // Smooth easing function
        }
      }
    })
  }
}
