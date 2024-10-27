# Register APK mime type for proper content-type header
Mime::Type.register "application/vnd.android.package-archive", :apk
Rack::Mime::MIME_TYPES[".apk"] = "application/vnd.android.package-archive"
