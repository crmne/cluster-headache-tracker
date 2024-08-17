// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

Honeybadger.configure({ apiKey: 'hbp_SiBMnG0vntYk9v4jW9iYNPfYRzoOTF3vuBGD' });

import { initializeCharts } from "./charts.js"

window.initializeCharts = initializeCharts;
