const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  darkMode: 'media',
  daisyui: {
    themes: [{
      light: {
        "primary": "#4f46e5",          // indigo-600
        "primary-content": "#ffffff",   // white text on primary
        "secondary": "#10b981",         // emerald-500
        "accent": "#f59e0b",           // amber-500
        "neutral": "#374151",          // gray-700
        "base-100": "#ffffff",         // white
        "info": "#3b82f6",            // blue-500
        "success": "#10b981",         // emerald-500
        "warning": "#f59e0b",         // amber-500
        "error": "#ef4444",           // red-500
      },
      dark: {
        "primary": "#4f46e5",          // indigo-600
        "primary-content": "#ffffff",   // white text on primary
        "secondary": "#10b981",         // emerald-500
        "accent": "#f59e0b",           // amber-500
        "neutral": "#1f2937",          // gray-800
        "base-100": "#111827",         // gray-900
        "info": "#3b82f6",            // blue-500
        "success": "#10b981",         // emerald-500
        "warning": "#f59e0b",         // amber-500
        "error": "#ef4444",           // red-500
      }
    }],
    darkTheme: "dark",
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('daisyui'),
  ],
}
