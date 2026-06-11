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

function formatDuration(value) {
  if (value < 1) {
    return `${(value * 60).toFixed(0)}m`
  } else if (value === 1) {
    return '1h'
  } else if (value < 24) {
    return `${value}h`
  } else {
    return `${(value / 24).toFixed(1)}d`
  }
}

function formatDurationLong(hours) {
  if (hours < 1) {
    return `${Math.round(hours * 60)} minutes`
  } else if (hours < 24) {
    return `${hours.toFixed(1)} hours`
  } else {
    return `${(hours / 24).toFixed(1)} days`
  }
}

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
          label: 'Headache Intensity',
          data: this.intensityValue,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      },
      options: {
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'day'
            }
          },
          y: {
            beginAtZero: true,
            max: 10
          }
        }
      }
    })
  }

  initializeTriggerChart() {
    if (!this.hasTriggerCanvasTarget) return

    this.drawPieChart('trigger', this.triggerCanvasTarget, 'Top 5 Triggers', this.triggerValue)
  }

  initializeMedicationChart() {
    if (!this.hasMedicationCanvasTarget) return

    this.drawPieChart('medication', this.medicationCanvasTarget, 'Top 5 Medications', this.medicationValue)
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
        labels: hourlyData.map(d => d.label),
        datasets: [
          {
            label: 'Frequency',
            data: hourlyData.map(d => d.frequency),
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            yAxisID: 'y-frequency',
          },
          {
            label: 'Avg Intensity',
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
              text: 'Time of Day'
            }
          },
          'y-frequency': {
            type: 'linear',
            position: 'left',
            title: {
              display: true,
              text: 'Frequency'
            },
            beginAtZero: true
          },
          'y-intensity': {
            type: 'linear',
            position: 'right',
            title: {
              display: true,
              text: 'Average Intensity'
            },
            beginAtZero: true,
            max: 10
          }
        },
        plugins: {
          title: {
            display: true,
            text: 'Headache Frequency and Intensity by Time of Day'
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
          label: 'Number of Attacks',
          data: this.attacksPerDayValue,
          backgroundColor: 'rgba(54, 162, 235, 0.6)',
          borderColor: 'rgb(54, 162, 235)',
          borderWidth: 1
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
              text: 'Date'
            }
          },
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Number of Attacks'
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
            text: 'Number of Attacks per Day'
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
          label: 'Attack Duration',
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
            type: 'time',
            time: {
              unit: 'day',
              displayFormats: {
                day: 'MMM d, yyyy'
              }
            },
            title: {
              display: true,
              text: 'Date'
            }
          },
          y: {
            type: maxDuration > 1 ? 'logarithmic' : 'linear',  // Use linear for small durations
            title: {
              display: true,
              text: 'Duration (hours)'
            },
            min: 0,  // Allow 0 on the scale
            suggestedMax: maxDuration > 0 ? maxDuration * 1.1 : 1,
            ticks: {
              callback: formatDuration,
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
                const date = new Date(context.raw.x).toLocaleDateString()
                return [
                  `Date: ${date}`,
                  `Duration: ${formatDurationLong(duration)}`,
                  `Intensity: ${intensity}/10`
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
