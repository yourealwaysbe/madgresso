# Madgresso

A Capybara-based script for automatically filling in Agresso expense claims, at
least for the installation i have to deal with...

## Requirements

* [Capybara 2.10.1](https://rubygems.org/gems/capybara)
* [Selenium Webdriver 2.53.4](https://rubygems.org/gems/selenium-webdriver/versions/2.53.4)
* [Chromium 53.0.2785.143](http://www.chromium.org/) or similar


## Usage

### Setting Up

First make sure you have a working Chrome/Chromium installed.
Then make sure you have Capybara and Selenium

    gem install capybara
    gem install selenium-webdriver

Then you should be able to run

    ./madgresso.rb


### Configuration

Configuration is by writing a ruby file that defines the right constants.  An
example (and the default configuration) can be found in
[configuration.rb](configuration.rb).

The configuration file used is either

* specified on the command line with -c
* found in ~/.config/madgresso/configuration.rb
* the default [configuration.rb](configuration.rb) distributed with the code

You'll need to set up your Agresso URL, username, password, any proxies you'd
like the web browser to use, and so on...

The most obscure is

    EXPENSE_TYPES = {
        'reg' => 'Conference Fees - Currency',
        ...
    }

which is just a map from convenient shortcuts ('reg') to the full expense item
type description in the Agresso drop-down box ('Conference Fees - Currency').
You can add as many as you find useful.


### Expense Claim Files

Basic usage is

    madgresso.rb <claim file>

where `<claim file>` is a file containing the details of the expense claim.
An example claim can be found in [example.claim](example.claim).
An expense claim file contains a number of lines.
All lines are optional (default values given in []).
General details are

    Month/Year: <month/year of claim> [default value: current month and year]
    Comment: <comment> [default value: '']
    Receipts: <path to pdf of receipt scans> [default value: don't add receipts]
    Project: <subproject code to override configured default>

Expense item rows are of the three possible formats

    <type>; <date>; <cur> <amount>; <desc>
    <type>; <date>; <cur> <amount>; <account>; <desc>
    <type>; <date>; <cur> <amount>; <account>; <sub-project>; <desc>

E.g.

    plane; 12 Oct; GBP 100; Item 1: My flight to Singapore
    plane; 12 Oct; GBP 100; 6050; Item 1: My flight to Singapore
    plane; 12 Oct; GBP 100; 6050; R10101-01; Item 1: My flight to Singapore

`<cur>` is given as a 3-char currency code followed by the value.  Don't worry
about upper case.  For mileage, use the code MIL and the amount is the number of
miles.  E.g.

    bike; 12 Oct; MIL 13; Item 1: My cycle to Paddington and back

The `<account>` is the account code (e.g. 6050 for staff travel).  The default
value is defined in the configuration file.  (If the default is `nil` then the
value assigned by Agresso is used.)

The `<subproject>` is the subproject code (e.g. R10101-01).  The default is
defined in the configuration file if not overriden by a `Project:` line.

The `<date>` can be given in any format ruby is happy with.  Missing values are
filled in with the current value.  E.g. '12 Oct' is read as '12 Oct 2016' (if
the program is being run on e.g. 25 Nov 2016).

Valid `<type>`s are defined in `EXPENSE_TYPES` in
[configuration.rb](configuration.rb).

Rows starting with '#' are ignored.


### Submitting a Claim

To make a claim, run

    madgresso.rb <claim file>

and watch it run.
Try not to disturb it, because inteferring can cause expected items to
disappear, which will cause the whole thing to crash.

Once it's done, it will leave you on the summary page, where you can save/submit
the claim after checking it over.
