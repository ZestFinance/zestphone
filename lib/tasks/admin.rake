namespace :admin do
  namespace :telephony do

    desc "Terminate all calls linked to current call" 
    task :call_full_terminate, [:number, :dry_run] => :environment do |task, args|
      config = args.to_hash

      #  Find call
      number  = config[:number]
      dry_run = config[:dry_run] == true || config[:dry_run] == 'true'
      call = Telephony::Call.find_all_by_number(number).last

      if call.nil?
        puts "Call with number: #{number} not found.  Try different formats (i.e. include dashes, or +1 at the front), and check whether agent is using twilio-client."
        return
      end

      #  Run termination - set output to console only for this run so we can see the details
      Rails.logger = Logger.new(STDOUT)
      call.terminate_conversation_and_all_call_legs(dry_run)
    end
  end
end
