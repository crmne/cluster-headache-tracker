import {
  Chart,
  TimeScale,
  LinearScale,
  PointElement,
  LineElement,
  LineController,
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
  PointElement,
  LineElement,
  LineController,
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

function initializeIntensityChart(intensityData) {
  if (intensityData && Object.keys(intensityData).length > 0) {
    const intensityCtx = document.getElementById('intensityChart');
    if (intensityCtx) {
      if (chartInstances.intensityChart) {
        chartInstances.intensityChart.destroy();
      }
      chartInstances.intensityChart = new Chart(intensityCtx, {
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
          responsive: true,
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
      chartInstances.triggerChart = new Chart(triggerCtx, {
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
      chartInstances.medicationChart = new Chart(medicationCtx, {
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
      chartInstances.hourlyChart = new Chart(hourlyCtx, {
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

export function initializeCharts(intensityData, triggerData, medicationData, hourlyData) {
  initializeIntensityChart(intensityData);
  initializeTriggerChart(triggerData);
  initializeMedicationChart(medicationData);
  initializeHourlyChart(hourlyData);
}
