namespace :demo do
  # Before submitting an app for review, reset the reviewers' account so its
  # made-up history ends today (see DemoAccount):
  #
  #   bin/kamal app exec -i --reuse "bin/rails demo:reset"      # appreview, asks for the password
  #   DEMO_PASSWORD=... bin/rails demo:reset
  #   DEMO_USERNAME=screenshots DEMO_ONGOING_ATTACK=1 DEMO_TIME_ZONE=Europe/Berlin DEMO_PASSWORD=... bin/rails demo:reset
  #
  # Logged times are the patient's wall clock, so an attack in progress started
  # minutes ago only reads that way in the time zone of the phone showing it.
  desc "Create or reset the synthetic App Store and Google Play review account"
  task reset: :environment do
    username = ENV.fetch("DEMO_USERNAME", "appreview")
    password = ENV["DEMO_PASSWORD"].presence || begin
      abort("Set DEMO_PASSWORD to the password reviewers will use.") unless $stdin.tty?

      require "io/console"
      print "Password for #{username}: "
      $stdin.noecho(&:gets).to_s.chomp.tap { puts }
    end
    abort("The password is empty.") if password.blank?

    time_zone = ActiveSupport::TimeZone[ENV.fetch("DEMO_TIME_ZONE", "UTC")] || abort("Unknown DEMO_TIME_ZONE")

    account = Current.set(time_zone: time_zone) do
      DemoAccount.reset!(username: username, password: password, ongoing_attack: ENV["DEMO_ONGOING_ATTACK"].present?)
    end
    puts "Reset #{username}: #{account.user.headache_logs.count} logs, #{account.user.medication_doses.count} doses"
  rescue DemoAccount::NotADemoAccount => error
    abort error.message
  end
end
