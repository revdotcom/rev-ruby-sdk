require 'rev-api'
require 'optparse'
require 'pp'

# An example app using the official Ruby SDK for the Rev.com API
#   This ruby script sets up a basic command line interface (CLI)
#   that prompts a user to authenticate on the web, then
#   allows them to type commands to manipulate their orders.
#
# To start, run:
# ruby examples/cli.rb --sandbox --client-key your_client_key --user-key your_user_key

class RevCLI
  COMMANDS = %w{help get list transcripts captions dl_transcripts dl_captions dl_sources place_tc place_cp cancel}

  def initialize
    options = { :environment => Rev::Api::PRODUCTION_HOST, :verbatim => false, :timestamps => false }
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: cli.rb [options]. You will be prompted for command then."

      opts.on("--client-key CLIENT-KEY", "Use CLIENT-KEY as the API Client Key for Authorization") do |client_key|
        options[:client_key] = client_key
      end

      opts.on("--user-key USER-KEY", "Use USER-KEY as the API User Key for Authorization") do |user_key|
        options[:user_key] = user_key
      end

      opts.on("--sandbox", "Execute against the Sandbox environment rather than production") do
        options[:environment] = Rev::Api::SANDBOX_HOST
      end

      opts.on("--[no-]verbatim", "Request verbatim transcription") do |v|
        options[:verbatim] = v
      end

      opts.on("--[no-]timestamps", "Request timestamps transcription") do |t|
        options[:timestamps] = t
      end
    end
    optparse.parse!

    raise OptionParser::MissingArgument, "--client-key" if options[:client_key].nil?
    raise OptionParser::MissingArgument, "--user-key" if options[:user_key].nil?

    @rev_client = Rev.new(options[:client_key], options[:user_key], options[:environment])
  end

  def command_loop
    puts "Enter a command or 'help' or 'exit'"
    command_line = ''

    while command_line.strip != 'exit'
      begin
        execute_command(command_line)
      rescue RuntimeError => e
        puts "Command Line Error! #{e.class}: #{e}"
        puts e.backtrace
      end
      print '> '
      command_line = gets.strip
    end

    puts 'Goodbye!'
    exit(0)
  end

  def execute_command(cmd_line)
    command = cmd_line.split
    method = command.first
    if COMMANDS.include? method
      begin
        send(method.to_sym, command[1..-1])
      rescue Rev::BadRequestError => e
        puts "Server returned error with code #{e.code}, message #{e.message}"
      rescue Rev::ApiError => e
        puts "Server returned error with message #{e.message}"
      end
    elsif command.first && !command.first.strip.empty?
      puts 'Invalid command. Type \'help\' to see commands.'
    end
  end

  def get(args)
    order_num = args[0]
    order = @rev_client.get_order order_num
    pp order
  end

  def list(args)
    orders = @rev_client.get_all_orders
    orders.each { |o| puts("#{o.order_number}") }

    puts 'There are no orders placed so far.' if orders.empty?
  end

  def transcripts(args)
    begin
      order_num = args[0]
      order = @rev_client.get_order order_num

      if order.transcripts.empty?
        puts "There are no transcripts for order #{order_num}"
        return
      end

      order.transcripts.each do |t|
        puts "Contents of #{t.name}"
        puts "-----------------------------------"
        puts @rev_client.get_attachment_content_as_string t.id
        puts
      end
    rescue Rev::BadRequestError => e
      puts "Displaying transcripts failed with error code #{e.code}, message #{e.message}"
    end
  end

  def captions(args)
    begin
      order_num = args[0]
      order = @rev_client.get_order order_num

      if order.captions.empty?
        puts "There are no captions for order #{order_num}"
        return
      end

      order.captions.each do |t|
        puts "Contents of #{t.name}"
        puts "-----------------------------------"
        puts @rev_client.get_attachment_content(t.id).body
        puts
      end
    rescue Rev::BadRequestError => e
      puts "Displaying captions failed with error code #{e.code}, message #{e.message}"
    end
  end

  def dl_transcripts(args)
    begin
      order_num = args[0]
      order = @rev_client.get_order order_num

      if order.transcripts.empty?
        puts "There are no transcripts for order #{order_num}"
        return
      end

      filenames = order.transcripts.map { |t| t.name}.join(',')
      puts "Downloading files: #{filenames}"
      order.transcripts.each do |t|
        @rev_client.save_attachment_content t.id, t.name
      end
    rescue Rev::BadRequestError => e
      puts "Downloading transcripts failed with error code #{e.code}, message #{e.message}"
    end
  end

  def dl_captions(args)
    begin
      order_num = args[0]
      order = @rev_client.get_order order_num

      if order.captions.empty?
        puts "There are no captions for order #{order_num}"
        return
      end

      filenames = order.captions.map { |t| t.name}.join(',')
      puts "Downloading files: #{filenames}"
      order.captions.each do |t|
        @rev_client.save_attachment_content t.id, t.name
      end
    rescue Rev::BadRequestError => e
      puts "Downloading captions failed with error code #{e.code}, message #{e.message}"
    end
  end

  def dl_sources(args)
    begin
      order_num = args[0]
      order = @rev_client.get_order order_num

      if order.sources.empty?
        puts "There are no source files for order #{order_num}"
        return
      end

      filenames = order.sources.map { |t| t.name }.join(',')
      puts "Downloading files: #{filenames}"
      order.sources.each do |t|
        @rev_client.save_attachment_content t.id, t.name
      end
    rescue Rev::BadRequestError => e
      puts "Downloading sources failed with error code #{e.code}, message #{e.message}"
    end
  end

  def cancel(args)
    begin
      order_num = args[0]
      @rev_client.cancel_order order_num
      puts "Order #{order_num} cancelled"
    rescue Rev::BadRequestError => e
      puts "Cancelling order failed with error code #{e.code}, message #{e.message}"
    end
  end

  def place_tc(args)
    inputs = upload(args, 'audio/mpeg')
    tc_options = Rev::TranscriptionOptions.new(inputs)
    place_helper(inputs, { :transcription_options => tc_options })
  end

  def place_cp(args)
    inputs = upload(args, 'video/mpeg')
    cp_options = Rev::CaptionOptions.new(inputs, {:output_file_formats => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:scc]] })
    place_helper(inputs, { :caption_options => cp_options })
  end

  def help(*args)
    puts "commands are: #{COMMANDS.join(' ')} help exit"
  end
  
  private
  
  def upload(args, type)
    input_urls = args.map do |f|
      puts "Uploading #{f}"
      @rev_client.upload_input(f, type)
    end
    input_urls.map { |url| Rev::Input.new(:uri => url, :audio_length => 3) }
  end
  
  def place_helper(inputs, options)
    payment = Rev::Payment.with_credit_card_on_file
    options = options.merge({ :payment => payment, :client_ref => 'XB432423', :comment => 'Please work quickly' })
    request = Rev::OrderRequest.new(payment, options)

    begin
      new_order = @rev_client.submit_order(request)
      puts "New order: #{new_order}"
    rescue Rev::BadRequestError => e
      puts "Order placement failed with error code #{e.code}, message #{e.message}"
    end
  end
  
end

cli = RevCLI.new
cli.command_loop
