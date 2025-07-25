import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  export(event) {
    event.preventDefault()

    // For Hotwire Native apps, we need to handle downloads differently
    if (window.webkit && window.webkit.messageHandlers) {
      // iOS - open in Safari
      window.location.href = this.urlValue
    } else if (window.HotwireNative) {
      // Android - use the download manager
      window.HotwireNative.openExternal(this.urlValue)
    } else {
      // Regular web browser - fetch and trigger download
      this.downloadFile()
    }
  }

  async downloadFile() {
    try {
      const response = await fetch(this.urlValue)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.style.display = 'none'
      a.href = url

      // Extract filename from response headers or use default
      const contentDisposition = response.headers.get('content-disposition')
      let filename = 'headache_logs.csv'
      if (contentDisposition) {
        const match = contentDisposition.match(/filename="?([^"]+)"?/)
        if (match) filename = match[1]
      }

      a.download = filename
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (error) {
      console.error('Download failed:', error)
      // Fallback to regular navigation
      window.location.href = this.urlValue
    }
  }
}