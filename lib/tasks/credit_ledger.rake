namespace :credit_ledger do
  desc "Verify all user balances match ledger"
  task verify_all: :environment do
    puts "Verifying all user balances..."

    results = BalanceVerificationService.audit_all_users

    puts "\n=== Verification Results ==="
    puts "Total users: #{results[:total]}"
    puts "Verified: #{results[:verified]}"
    puts "Mismatches: #{results[:mismatches].count}"
    puts "Errors: #{results[:errors].count}"

    if results[:mismatches].any?
      puts "\n=== Mismatches ==="
      results[:mismatches].each do |mismatch|
        puts "User #{mismatch[:user_id]}: #{mismatch[:errors].join(', ')}"
      end
    end

    if results[:errors].any?
      puts "\n=== Errors ==="
      results[:errors].each do |error|
        puts "User #{error[:user_id]}: #{error[:error]}"
      end
    end
  end

  desc "Verify single user balance (USER_ID=123)"
  task verify_user: :environment do
    user_id = ENV["USER_ID"]
    raise "USER_ID required" unless user_id

    user = User.find(user_id)
    service = BalanceVerificationService.new(user)

    puts "Verifying user #{user.id} (#{user.email})..."

    if service.verify
      puts "✓ Balance verified"

      summary = service.transaction_summary
      puts "\n=== Summary ==="
      puts "Total entries: #{summary[:total_entries]}"
      puts "Credits added: #{summary[:total_credits_added]}"
      puts "Credits spent: #{summary[:total_credits_spent]}"
      puts "Current balance: #{summary[:current_balance]}"
    else
      puts "✗ Balance mismatch!"
      service.errors.each { |error| puts "  #{error}" }

      # Perform deep audit
      audit_result = service.audit
      puts "\n=== Deep Audit ==="
      puts "Expected: #{audit_result[:expected]}"
      puts "Actual: #{audit_result[:actual]}"
    end
  end

  desc "Detect anomalies in credit activity (DAYS=7)"
  task detect_anomalies: :environment do
    days = (ENV["DAYS"] || 7).to_i

    puts "Detecting anomalies in last #{days} days..."

    anomalies = BalanceVerificationService.detect_anomalies(days: days)

    if anomalies.any?
      puts "\n=== Found #{anomalies.count} Anomalies ==="
      anomalies.each do |anomaly|
        puts "User #{anomaly[:user_id]}: #{anomaly[:reason]}"
        puts "  Details: #{anomaly.except(:user_id, :reason).inspect}"
      end
    else
      puts "No anomalies detected."
    end
  end

  desc "Backfill ledger from existing transactions (DANGER: only run once)"
  task backfill: :environment do
    puts "WARNING: This task backfills ledger from existing data."
    puts "It should only be run ONCE during initial deployment."
    print "Continue? (yes/no): "

    response = STDIN.gets.chomp
    exit unless response.downcase == "yes"

    puts "\nBackfilling ledger entries..."

    # This would contain logic to create ledger entries from existing
    # btc_transactions and spot_purchases
    # Implementation depends on data quality and whether to preserve timestamps

    puts "Backfill complete. Run 'rake credit_ledger:verify_all' to verify."
  end
end
