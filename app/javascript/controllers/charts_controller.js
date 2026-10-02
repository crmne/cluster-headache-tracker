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
    "container"
  ]

  static values = {
    intensity: Array,
    trigger: Object,
    medication: Object,
    hourly: Array,
    attacksPerDay: Array,
    duration: Array
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
      } catch (error) {
        console.error('Error initializing charts:', error)
      } finally {
        this.containerTargets.forEach(container => container.classList.remove('loading'))
      }
    })
  }

  initializeIntensityChart() {
    if (!this.hasIntensityCanvasTarget || this.intensityValue.length === 0) return

    this.drawChart('intensity', this.intensityCanvasTarget, {
      type: 'line',
      data: {
        datasets: [{
          label: t('charts.intensity.label'),
          data: this.intensityValue,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      },
      options: {
        scales: {
          x: timeAxis,
          y: {
            beginAtZero: true,
            max: 10
          }
        },
        plugins: {
          tooltip: {
            callbacks: { title: dayTooltipTitle }
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

    this.drawPieChart('medication', this.medicationCanvasTarget, t('charts.medications.title'), this.medicationValue)
  }

  drawPieChart(key, canvas, title, data) {
    if (Object.keys(data).length === 0) return

    this.drawChart(key, canvas, {
      type: 'pie',
      data: {
        labels: Object.keys(data),
        datasets: [{
          data: Object.values(data),
          backgroundColor: [
            'rgb(255, 99, 132)',
            'rgb(54, 162, 235)',
            'rgb(255, 205, 86)',
            'rgb(75, 192, 192)',
            'rgb(153, 102, 255)'
          ]
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
