#!/usr/bin/env ruby

require 'optparse'
require 'capybara'
require 'selenium-webdriver'

require_relative 'expenses'

HOME_CONFIG = '~/.config/madgresso/configuration.rb'


# Parse the options, set up the environment

config_loaded = false

opt_parser = OptionParser.new do |opts|
    opts.banner = 'Usage madgresso.rb [options] <info file>'

    opts.on('-c', '--config CONFIG_FILE',
            'Use specified config file instead of default',
            'or ' + HOME_CONFIG,
            '   (should be a ruby file, see',
            '    example configuration.rb)') do |conf|
        require File.expand_path(conf)
        config_loaded = true
    end
end
opt_parser.parse!(ARGV)

if ARGV.empty?
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

claim = Expenses.new(File.expand_path(ARGV[0]),
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
    Capybara::Selenium::Driver.new(app,
        :browser => :chrome,
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
wb.fill_in('ctl00$ctl02', :with => PASSWORD)


# Create new expense claim

wb.within_frame wb.find('#_menuFrame') do
    wb.find('.MenuModuleTitle', :text => 'Time and expenses').click
    wb.find('.AppMenuItemTitle', :text => 'Expenses').click
    wb.find('#applicationMenu_ctl16_R-TT97').click
end



# Fill in first page, sleep to make sure it's loaded
sleep 2

wb.within_frame wb.find('#containerFrame') do
    wb.within_frame wb.find('#contentContainerFrame') do
        wb.fill_in('Month/Year of Claim', :with => claim.month_year)
        # Need to fill in a dummy value first for some reason...
        wb.fill_in('Comment', :with => '')
        wb.fill_in('Comment', :with => claim.comment)
        wb.find('.TitleCell', :text => 'Next step').click
    end
end


# Fill in items

wb.within_frame wb.find('#containerFrame') do
    wb.within_frame wb.find('#contentContainerFrame') do
        claim.items.each do |item|
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
        if not claim.receipts.nil?
            $doc_win = wb.window_opened_by do
                wb.find('.RibbonButtonTitle', :text => 'Documents').click
            end
        end
    end
end

if not claim.receipts.nil?
    wb.within_window $doc_win do
        wb.within_frame wb.find('#contentContainerFrame') do
            wb.find('.TitleCell', :text => 'Add existing document').click
            wb.find('input[type=file]').set(claim.receipts)
            wb.find('.TitleCell', :text => 'OK').click
        end
    end
    $doc_win.close
end


# Done, go to summary and wait for user to agree.

wb.within_frame wb.find('#containerFrame') do
    wb.within_frame wb.find('#contentContainerFrame') do
        wb.find('.TitleCell', :text => 'Next step').click
    end
end

puts 'When done, press enter.'
$stdin.gets

