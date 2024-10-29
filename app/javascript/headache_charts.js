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
  return new Chart(ctx, {
    ...config,
    options: {
      ...config.options,
      responsive: true,
      maintainAspectRatio: false
    }
  });
}

function initializeIntensityChart(intensityData) {
  if (intensityData && Object.keys(intensityData).length > 0) {
    const intensityCtx = document.getElementById('intensityChart');
    if (intensityCtx) {
      if (chartInstances.intensityChart) {
        chartInstances.intensityChart.destroy();
      }
      chartInstances.intensityChart = createChart(intensityCtx, {
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
  }
}

function initializeTriggerChart(triggerData) {
  if (triggerData && Object.keys(triggerData).length > 0) {
    const triggerCtx = document.getElementById('triggerChart');
    if (triggerCtx) {
      if (chartInstances.triggerChart) {
        chartInstances.triggerChart.destroy();
      }
      chartInstances.triggerChart = createChart(triggerCtx, {
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
          responsive: true,
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
  }
}

function initializeMedicationChart(medicationData) {
  if (medicationData && Object.keys(medicationData).length > 0) {
    const medicationCtx = document.getElementById('medicationChart');
    if (medicationCtx) {
      if (chartInstances.medicationChart) {
        chartInstances.medicationChart.destroy();
      }
      chartInstances.medicationChart = createChart(medicationCtx, {
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
          responsive: true,
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
  }
}

function initializeHourlyChart(hourlyData) {
  if (hourlyData && hourlyData.length > 0) {
    const hourlyCtx = document.getElementById('hourlyChart');
    if (hourlyCtx) {
      if (chartInstances.hourlyChart) {
        chartInstances.hourlyChart.destroy();
      }
      chartInstances.hourlyChart = createChart(hourlyCtx, {
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
          responsive: true,
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
  }
}

function initializeAttacksPerDayChart(attacksPerDayData) {
  if (attacksPerDayData && Object.keys(attacksPerDayData).length > 0) {
    const attacksPerDayCtx = document.getElementById('attacksPerDayChart');
    if (attacksPerDayCtx) {
      if (chartInstances.attacksPerDayChart) {
        chartInstances.attacksPerDayChart.destroy();
      }
      chartInstances.attacksPerDayChart = createChart(attacksPerDayCtx, {
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
          responsive: true,
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
  }
}

function showLoading(chartId) {
  const chartContainer = document.getElementById(chartId + 'Container');
  if (chartContainer) {
    chartContainer.classList.add('loading');
  }
}

function hideLoading(chartId) {
  const chartContainer = document.getElementById(chartId + 'Container');
  if (chartContainer) {
    chartContainer.classList.remove('loading');
  }
}

function initializeDurationChart(durationData) {
  if (durationData && durationData.length > 0) {
    const durationCtx = document.getElementById('durationChart');
    if (durationCtx) {
      if (chartInstances.durationChart) {
        chartInstances.durationChart.destroy();
      }

      // Filter out any zero or undefined durations to avoid log(0) issues
      const validData = durationData.filter(d => d.y > 0);

      // Calculate geometric mean for log scale
      const logSum = validData.reduce((acc, curr) => acc + Math.log(curr.y), 0);
      const geometricMean = Math.exp(logSum / validData.length);

      // Find min and max for better scale configuration
      const minDuration = Math.min(...validData.map(d => d.y));
      const maxDuration = Math.max(...validData.map(d => d.y));

      chartInstances.durationChart = createChart(durationCtx, {
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
                callback: function(value) {
                  if (value < 1) {
                    return (value * 60).toFixed(0) + 'm';
                  } else if (value === 1) {
                    return '1h';
                  } else if (value < 24) {
                    return value + 'h';
                  } else {
                    return (value / 24).toFixed(1) + 'd';
                  }
                },
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
                  let durationStr;
                  if (duration < 1) {
                    durationStr = `${Math.round(duration * 60)} minutes`;
                  } else if (duration < 24) {
                    durationStr = `${duration.toFixed(1)} hours`;
                  } else {
                    durationStr = `${(duration / 24).toFixed(1)} days`;
                  }
                  return [
                    `Date: ${date}`,
                    `Duration: ${durationStr}`,
                    `Intensity: ${intensity}/10`
                  ];
                }
              }
            },
            annotation: {
              annotations: {
                average: {
                  type: 'line',
                  yMin: geometricMean,
                  yMax: geometricMean,
                  borderColor: 'rgba(255, 99, 132, 0.8)',
                  borderWidth: 2,
                  borderDash: [6, 6],
                  label: {
                    display: true,
                    content: formatDuration(geometricMean) + ' (geometric mean)',
                    position: 'start'
                  }
                }
              }
            }
          }
        }
      });
    }
  }
}

// Helper function to format duration consistently
function formatDuration(hours) {
  if (hours < 1) {
    return `${Math.round(hours * 60)}m`;
  } else if (hours < 24) {
    return `${hours.toFixed(1)}h`;
  } else {
    return `${(hours / 24).toFixed(1)}d`;
  }
}

export function initializeCharts(intensityData, triggerData, medicationData, hourlyData, attacksPerDayData, durationData) {
  showLoading('intensity');
  showLoading('trigger');
  showLoading('medication');
  showLoading('hourly');
  showLoading('attacksPerDay');
  showLoading('duration');

  setTimeout(() => {
    initializeIntensityChart(intensityData);
    initializeTriggerChart(triggerData);
    initializeMedicationChart(medicationData);
    initializeHourlyChart(hourlyData);
    initializeAttacksPerDayChart(attacksPerDayData);
    initializeDurationChart(durationData);

    hideLoading('intensity');
    hideLoading('trigger');
    hideLoading('medication');
    hideLoading('hourly');
    hideLoading('attacksPerDay');
    hideLoading('duration');
  }, 0);
}
