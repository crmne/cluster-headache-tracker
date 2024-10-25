# Pin npm packages by running ./bin/importmap

pin "application"
pin "tailwind.config"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Chart.js and its dependencies
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.3.0/dist/chart.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
pin "chartjs-adapter-date-fns", to: "https://ga.jspm.io/npm:chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.esm.js"
pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@2.30.0/esm/index.js"

# Add these new pins for @babel/runtime
pin "@babel/runtime/helpers/esm/typeof", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/typeof.js"
pin "@babel/runtime/helpers/esm/toPrimitive", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/toPrimitive.js"
pin "@babel/runtime/helpers/esm/toPropertyKey", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/toPropertyKey.js"
pin "@babel/runtime/helpers/esm/createForOfIteratorHelper", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/createForOfIteratorHelper.js"
pin "@babel/runtime/helpers/esm/assertThisInitialized", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/assertThisInitialized.js"
pin "@babel/runtime/helpers/esm/inherits", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/inherits.js"
pin "@babel/runtime/helpers/esm/createSuper", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/createSuper.js"
pin "@babel/runtime/helpers/esm/classCallCheck", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/classCallCheck.js"
pin "@babel/runtime/helpers/esm/createClass", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/createClass.js"
pin "@babel/runtime/helpers/esm/defineProperty", to: "https://ga.jspm.io/npm:@babel/runtime@7.22.5/helpers/esm/defineProperty.js"

# Honeybadger
pin "@honeybadger-io/js", to: "@honeybadger-io--js.js" # @6.9.3

# Charts
pin "headache_charts", to: "headache_charts.js"
