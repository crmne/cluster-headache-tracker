// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { initializeCharts } from "./charts/main.js"

window.initializeCharts = initializeCharts;
