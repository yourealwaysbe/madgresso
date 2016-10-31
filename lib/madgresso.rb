#!/usr/bin/env ruby

require 'optparse'
require 'capybara'
require 'selenium-webdriver'

require_relative 'expenses'
require_relative 'interactive'

HOME_CONFIG = '~/.config/madgresso/configuration.rb'


class Madgresso
    # Runs the madgresso script on creation
    # Param
    #  +args+:: the ARGV array to process
    def self.run(args)

        # Parse the options, set up the environment

        config_loaded = false
        interactive = false
        month_year = Time.now.strftime('%B %Y')
        comment = ''
        save_file_name = nil

        opt_parser = OptionParser.new do |opts|
            opts.banner = 'Usage madgresso.rb [options] <info file1> <info file2> ...'

            opts.on('-c', '--config CONFIG_FILE',
                    'Use specified config file instead of default',
                    'or ' + HOME_CONFIG,
                    '   (should be a ruby file, see',
                    '    example configuration.rb)') do |conf|
                require File.expand_path(conf)
                config_loaded = true
            end
            opts.on('-i', '--interactive',
                    'Run in interactive mode where input is',
                    'read from stdin (ctrl-D to terminate).',
                    'Note: this can be used in conjunction',
                    'with a claim file to add additional items.') do
                interactive = true
            end
            opts.on('-m', '--month-year MONTH_YEAR',
                    'Specify month/year field in interactive mode',
                    'else current time will be used') do |my|
                month_year = my
            end
            opts.on('-r', '--comment COMMENT',
                    'Specify comment field in interactive mode',
                    'else will be empty') do |cmt|
                comment = cmt
            end
            opts.on('-w', '--write FILE',
                    'If in interactive mode, save input to FILE',
                    'so it can be replayed in case of error.') do |save_file|
                save_file_name = save_file
            end
        end
        opt_parser.parse!(args)

        if not interactive and args.empty?
            puts opt_parser
            exit -1
        end

        if not config_loaded
            home_conf = File.expand_path(HOME_CONFIG)
            if File.exists?(home_conf)
                require home_conf
            else
                require_relative 'configuration.rb'
            end
        end


        input_streams = []

        args.each do |filename|
            input_streams.push  File.open(File.expand_path(filename), 'r')
        end

        if interactive
            save_file = nil
            if not save_file_name.nil?
                save_file = open(save_file_name, 'w')
                save_file.puts("Month: #{month_year}")
                save_file.puts("Comment: #{comment}")
            end
            input_streams.push Interactive.new(save_file)
        end

        claim = Expenses.new(input_streams,
                             DEFAULT_ACCOUNT,
                             DEFAULT_SUBPROJ)


        # Set up browser

        Capybara.default_max_wait_time = 10
        Capybara.wait_on_first_by_default = true
        Capybara.register_driver :selenium do |app|
            args = []
            if not PROXY.nil?
                args << "--proxy-server=#{PROXY}"
            end
            # Set high timeout for uploading oversized receipt files
            client = Selenium::WebDriver::Remote::Http::Default.new
            client.timeout = 600
            Capybara::Selenium::Driver.new(app,
                :browser => :chrome,
                :http_client => client,
                :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.chrome(
                    'chromeOptions' => {
                        'args' => args
                    }
                )
            )
        end
        wb = Capybara::Session.new :selenium # instantiate new session object
        wb.visit(AGRESSO_URL)


        # Log in

        wb.fill_in('ctl00$ctl00', :with => USERNAME)
        wb.fill_in('ctl00$ctl01', :with => 'CC')
        if not PASSWORD.nil?
            wb.fill_in('ctl00$ctl02', :with => PASSWORD)
        end


        # Create new expense claim

        # wait for a long time to allow password entry
        password_wait = PASSWORD.nil? ? 100000 : Capybara.default_max_wait_time

        wb.within_frame wb.find('#_menuFrame', :wait => password_wait) do
            wb.find('.MenuModuleTitle', :text => 'Time and expenses').click
            wb.find('.AppMenuItemTitle', :text => 'Expenses').click
            wb.find('#applicationMenu_ctl16_R-TT97').click
        end



        # Fill in first page, sleep to make sure it's loaded
        sleep 2

        wb.within_frame wb.find('#containerFrame') do
            wb.within_frame wb.find('#contentContainerFrame') do
                wb.fill_in('Month/Year of Claim', :with => month_year)
                # Need to fill in a dummy value first for some reason...
                wb.fill_in('Comment', :with => '')
                wb.fill_in('Comment', :with => comment)
                wb.find('.TitleCell', :text => 'Next step').click
            end
        end


        # Fill in items

        wb.within_frame wb.find('#containerFrame') do
            wb.within_frame wb.find('#contentContainerFrame') do
                claim.items.each do |item|
                    # Check if ok
                    if EXPENSE_TYPES[item.type].nil?
                        puts "#{item.type} not recognised, ignoring item."
                        next
                    end

                    # First click add
                    wb.find('.TitleCell', :text => 'Add').click

                    # Next fill in type, open drop down by filling text box
                    wb.fill_in('Expense type', :with => ' ')
                    wb.first('.slcPopup td', :text => EXPENSE_TYPES[item.type]).click
                    # Click something to remove focus and move on
                    wb.find('.TopLabel', :text => 'Expense type').click

                    # Now complete form appears, fill it in (i'll not document all the
                    # hacks required because it's bound to be full of them...)
                    wb.fill_in('Date', :with => item.date.strftime('%d/%m/%Y'))
                    wb.fill_in('Description', :with => ' ')
                    wb.fill_in('Description', :with => item.description)

                    if item.currency.upcase == MILEAGE_CODE
                        wb.fill_in('Miles', :with => item.amount)
                    elsif item.currency.strip.empty?
                        if wb.has_no_field?('Curr. amount', :wait => 0)
                            wb.fill_in('Amount', :with => item.amount)
                        else
                            wb.fill_in('Curr. amount', :with => item.amount)
                        end
                    elsif wb.has_no_field?('Currency', :wait => 0)
                        puts 'No currency field found, ignoring specified currency.'
                        wb.fill_in('Amount', :with => item.amount)
                    else
                        wb.fill_in('Currency', :with => item.currency.upcase)
                        wb.fill_in('Curr. amount', :with => ' ')
                        wb.fill_in('Curr. amount', :with => item.amount)
                    end

                    if not item.account.nil?
                        wb.fill_in('Account', :with => item.account)
                    else
                        wb.fill_in('Subproj', :with => '')
                    end
                    wb.fill_in('Subproj', :with => item.subproject)
                    wb.first('.slcPopup td', :text => item.subproject).click

                    # Click something to remove focus and move on
                    wb.find('.TopLabel', :text => 'Description').click
                end

                # Get window for adding documents
                if not claim.receipts.empty?
                    $doc_win = wb.window_opened_by do
                        wb.find('.RibbonButtonTitle', :text => 'Documents').click
                    end
                end
            end
        end


        # Post-processing: update receipts, comment, month if needed

        if not claim.receipts.empty?
            wb.within_window $doc_win do
                wb.within_frame wb.find('#contentContainerFrame') do
                    claim.receipts.each do |receipt|
                        fullpath = File.expand_path(receipt)
                        wb.find('.TitleCell', :text => 'Add existing document').click
                        wb.find('input[type=file]').set(fullpath)
                        wb.find('.TitleCell', :text => 'OK').click
                    end
                end
            end
            $doc_win.close
        end

        if not (claim.comment.nil? and
                claim.month.nil?)
             wb.within_frame wb.find('#containerFrame') do
                wb.within_frame wb.find('#contentContainerFrame') do
                    wb.find('.TitleCell', :text => 'Previous step').click
                    if not claim.month.nil?
                        wb.fill_in('Month/Year of Claim', :with => claim.month)
                    end
                    if not claim.comment.nil?
                        # Need to fill in a dummy value first for some reason...
                        wb.fill_in('Comment', :with => '')
                        wb.fill_in('Comment', :with => claim.comment)
                    end
                    wb.find('.TitleCell', :text => 'Next step').click
                end
            end
        end


        # Done, go to summary and wait for user to agree.

        wb.within_frame wb.find('#containerFrame') do
            wb.within_frame wb.find('#contentContainerFrame') do
                wb.find('.TitleCell', :text => 'Next step').click
            end
        end

        puts 'When done, press enter.'
        $stdin.gets
    end
end
