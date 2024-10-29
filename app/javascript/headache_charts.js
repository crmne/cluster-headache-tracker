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
} from "chart.js";
import "chartjs-adapter-date-fns";

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
);

let chartInstances = {};

function createChart(ctx, config) {
  // Clear any existing chart in this context
  if (chartInstances[ctx.canvas.id]) {
    chartInstances[ctx.canvas.id].destroy();
  }

  // Create new chart
  chartInstances[ctx.canvas.id] = new Chart(ctx, {
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
  });

  return chartInstances[ctx.canvas.id];
}

// Helper function to safely get chart context
function getChartContext(chartId) {
  const canvas = document.getElementById(chartId);
  return canvas ? canvas.getContext('2d') : null;
}

function initializeIntensityChart(intensityData) {
  const ctx = getChartContext('intensityChart');
  if (ctx && intensityData && Object.keys(intensityData).length > 0) {
    return createChart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Headache Intensity',
          data: intensityData,
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
    });
  }
  return null;
}

function initializeTriggerChart(triggerData) {
  const ctx = getChartContext('triggerChart');
  if (ctx && triggerData && Object.keys(triggerData).length > 0) {
    return createChart(ctx, {
      type: 'pie',
      data: {
        labels: Object.keys(triggerData),
        datasets: [{
          data: Object.values(triggerData),
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
            text: 'Top 5 Triggers'
          }
        }
      }
    });
  }
  return null;
}

function initializeMedicationChart(medicationData) {
  const ctx = getChartContext('medicationChart');
  if (ctx && medicationData && Object.keys(medicationData).length > 0) {
    return createChart(ctx, {
      type: 'pie',
      data: {
        labels: Object.keys(medicationData),
        datasets: [{
          data: Object.values(medicationData),
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
            text: 'Top 5 Medications'
          }
        }
      }
    });
  }
  return null;
}

function initializeHourlyChart(hourlyData) {
  const ctx = getChartContext('hourlyChart');
  if (ctx && hourlyData && hourlyData.length > 0) {
    return createChart(ctx, {
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
    });
  }
  return null;
}

function initializeAttacksPerDayChart(attacksPerDayData) {
  const ctx = getChartContext('attacksPerDayChart');
  if (ctx && attacksPerDayData && attacksPerDayData.length > 0) {
    return createChart(ctx, {
      type: 'bar',
      data: {
        datasets: [{
          label: 'Number of Attacks',
          data: attacksPerDayData,
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
    });
  }
  return null;
}

function initializeDurationChart(durationData) {
  const ctx = getChartContext('durationChart');
  if (ctx && durationData && durationData.length > 0) {
    const validData = durationData.filter(d => d.y > 0);
    if (validData.length === 0) return null;

    const logSum = validData.reduce((acc, curr) => acc + Math.log(curr.y), 0);
    const geometricMean = Math.exp(logSum / validData.length);
    const minDuration = Math.min(...validData.map(d => d.y));
    const maxDuration = Math.max(...validData.map(d => d.y));

    return createChart(ctx, {
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
            type: 'logarithmic',
            title: {
              display: true,
              text: 'Duration (hours)'
            },
            min: Math.max(0.1, minDuration / 2),
            suggestedMax: maxDuration * 1.1,
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
                const duration = context.raw.y;
                const intensity = context.raw.intensity;
                const date = new Date(context.raw.x).toLocaleDateString();
                return [
                  `Date: ${date}`,
                  `Duration: ${formatDurationLong(duration)}`,
                  `Intensity: ${intensity}/10`
                ];
              }
            }
          }
        }
      }
    });
  }
  return null;
}

function formatDuration(value) {
  if (value < 1) {
    return `${(value * 60).toFixed(0)}m`;
  } else if (value === 1) {
    return '1h';
  } else if (value < 24) {
    return `${value}h`;
  } else {
    return `${(value / 24).toFixed(1)}d`;
  }
}

function formatDurationLong(hours) {
  if (hours < 1) {
    return `${Math.round(hours * 60)} minutes`;
  } else if (hours < 24) {
    return `${hours.toFixed(1)} hours`;
  } else {
    return `${(hours / 24).toFixed(1)} days`;
  }
}

export function initializeCharts(intensityData, triggerData, medicationData, hourlyData, attacksPerDayData, durationData) {
  // Initialize all chart containers with loading state
  const containers = ['intensity', 'trigger', 'medication', 'hourly', 'attacksPerDay', 'duration'];
  containers.forEach(id => showLoading(id));

  // Use requestAnimationFrame to ensure DOM is ready and loading states are visible
  requestAnimationFrame(() => {
    // Initialize each chart independently
    Promise.all([
      new Promise(resolve => {
        initializeIntensityChart(intensityData);
        hideLoading('intensity');
        resolve();
      }),
      new Promise(resolve => {
        initializeTriggerChart(triggerData);
        hideLoading('trigger');
        resolve();
      }),
      new Promise(resolve => {
        initializeMedicationChart(medicationData);
        hideLoading('medication');
        resolve();
      }),
      new Promise(resolve => {
        initializeHourlyChart(hourlyData);
        hideLoading('hourly');
        resolve();
      }),
      new Promise(resolve => {
        initializeAttacksPerDayChart(attacksPerDayData);
        hideLoading('attacksPerDay');
        resolve();
      }),
      new Promise(resolve => {
        initializeDurationChart(durationData);
        hideLoading('duration');
        resolve();
      })
    ]).catch(error => {
        console.error('Error initializing charts:', error);
        // Hide all loading indicators in case of error
        containers.forEach(id => hideLoading(id));
      });
  });
}

function showLoading(chartId) {
  const container = document.getElementById(`${chartId}ChartContainer`);
  if (container) {
    container.classList.add('loading');
  }
}

function hideLoading(chartId) {
  const container = document.getElementById(`${chartId}ChartContainer`);
  if (container) {
    container.classList.remove('loading');
  }
}
