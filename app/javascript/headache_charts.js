import {
  Chart,
  TimeScale,
  LinearScale,
  PointElement,
  LineElement,
  LineController,
  PieController,
  ArcElement,
  Legend,
  Title,
  Tooltip
} from "chart.js";
import "chartjs-adapter-date-fns";

Chart.register(
  TimeScale,
  LinearScale,
  PointElement,
  LineElement,
  LineController,
  PieController,
  ArcElement,
  Legend,
  Title,
  Tooltip
);

export function initializeCharts(intensityData, triggerData, medicationData) {
  const intensityCtx = document.getElementById('intensityChart');
  if (intensityCtx) {
    new Chart(intensityCtx, {
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

  if (triggerData && Object.keys(triggerData).length > 0) {
    const triggerCtx = document.getElementById('triggerChart');
    if (triggerCtx) {
      new Chart(triggerCtx, {
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
  if (medicationData && Object.keys(medicationData).length > 0) {
    const medicationCtx = document.getElementById('medicationChart');
    if (medicationCtx) {
      new Chart(medicationCtx, {
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
