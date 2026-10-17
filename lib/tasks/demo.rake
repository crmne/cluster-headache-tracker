namespace :demo do
  # Before submitting an app for review, reset the reviewers' account so its
  # made-up history ends today (see DemoAccount):
  #
  #   DEMO_PASSWORD=... bin/rails demo:reset                      # appreview
  #   DEMO_USERNAME=screenshots DEMO_ONGOING_ATTACK=1 DEMO_PASSWORD=... bin/rails demo:reset
  desc "Create or reset the synthetic App Store and Google Play review account"
  task reset: :environment do
    username = ENV.fetch("DEMO_USERNAME", "appreview")
    password = ENV["DEMO_PASSWORD"].presence || abort("Set DEMO_PASSWORD to the password reviewers will use.")

    account = DemoAccount.reset!(username: username, password: password, ongoing_attack: ENV["DEMO_ONGOING_ATTACK"].present?)
    puts "Reset #{username}: #{account.user.headache_logs.count} logs, #{account.user.medication_doses.count} doses"
  rescue DemoAccount::NotADemoAccount => error
    abort error.message
  end
end
