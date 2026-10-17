# Encrypting health data that was stored before encryption (ContentEncryption):
#
# 1. Deploy with support_unencrypted_data on (config/application.rb).
# 2. bin/rails encryption:encrypt: encrypts what's still plain text. Safe to
#    stop and run again.
# 3. bin/rails encryption:verify: exits non-zero while any row is left.
# 4. Turn support_unencrypted_data off and deploy again.
namespace :encryption do
  desc "Encrypt health data stored before encryption at rest"
  task encrypt: :environment do
    ContentEncryption.encrypt_pending do |model, count|
      puts "#{model.name}: encrypted #{count} rows"
    end
  end

  desc "Count rows whose health data is still unencrypted"
  task verify: :environment do
    pending = ContentEncryption.pending
    pending.each { |model, count| puts "#{model.name}: #{count} unencrypted rows" }

    if pending.values.sum.positive?
      abort "Some health data is still unencrypted"
    else
      puts "All health data is encrypted"
    end
  end
end
