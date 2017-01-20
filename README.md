# Madgresso

A Capybara-based script for automatically filling in Agresso expense claims, at
least for the installation i have to deal with...

Can either be done via expense claim files or interactively on the command line.

## Requirements

* [Capybara 2.10.1](https://rubygems.org/gems/capybara)
* [Selenium Webdriver 2.53.4](https://rubygems.org/gems/selenium-webdriver/versions/2.53.4)
* [Chromium 53.0.2785.143](http://www.chromium.org/) or similar


## Usage

### Setting Up

First make sure you have a working Chrome/Chromium installed.

Then you should be able to run

    gem build madgresso.gemspec
    gem install madgresso-0.0.1.gem

Then
    
    madgresso

should be an executable in your PATH.


### Configuration

Configuration is by writing a ruby file that defines the right constants.  An
example (and the default configuration) can be found in
[configuration.rb](lib/configuration.rb).

The configuration file used is either

* specified on the command line with -c
* found in ~/.config/madgresso/configuration.rb
* the default [configuration.rb](lib/configuration.rb) distributed with the code

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

    madgresso <claim file> [-m <month/year>] [-r <comment>]

where `<claim file>` is a file containing the details of the expense claim.
The `<month/year>` and `<comment>` arguments should be provided if the default
values are not sufficient (default is current month/year and a blank comment).

An example claim file can be found in [example.claim](example.claim).
An expense claim file contains a number of lines.
All lines are optional.
General details are

    Receipts: <path to pdf of receipt scans> [default value: don't add receipts]
    Project: <subproject code to override configured default>
    Comment: <change the comment to override the default>
    Month: <change the month/year field to override the default>

Multiple receipts can be specified both on separate lines and by entering a glob
(E.g. `*.pdf`).  Setting the project applies to all future claim items, so you
can change it mid-file.  Comment, Month, and Receipts are applied after the
expense claim is completed (ctrl-D or EOF).

Expense item rows are of the three possible formats

    <type>; <date>; <cur> <amount>; <desc>
    <type>; <date>; <cur> <amount>; <account>; <desc>
    <type>; <date>; <cur> <amount>; <account>; <sub-project>; <desc>

E.g.

    plane; 12 Oct; GBP 100; Item 1: My flight to Singapore
    plane; 12 Oct; GBP 100; 6050; Item 1: My flight to Singapore
    plane; 12 Oct; GBP 100; 6050; R10101-01; Item 1: My flight to Singapore

`<cur>` is given as a 3-char currency code followed by the value.  Don't worry
about upper case.  If this is empty, the default currenty given by Agresso will
be accepted.  For mileage, use the code MIL and the amount is the number of
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


### Interactive Mode

Instead of writing a file and processing it, you can run madgresso interactively.
In this case, you supply the month/year and comment on the command line, if the
default values (current month/year, and '') are not sufficient.

    madgresso -i [-m <month/year>] [-r <comment>]

Then, items are added just like the files

    plane; 10 oct; eur 100; item 1: flight to London
    receipts: ~/myreceipts.pdf

The receipts file can be tab-completed.  Multiple receipts files can be
specified, but they are all added at the end, not right away.  Similarly if
Month or Comment is used to update these fields.

To finish, use ctrl-D.

To mirror your input to a file (to protect against things going wrong and having
to type everything again), use `-w <file name>` alongside `-i`


### Protecting Against / Recovering From Crashes

If using interactive mode it'd be hella annoying if the thing crashed after you
just typed out 20 items.  Hence, use `-w <file name>` to mirror your typing to a
file.  You can then run

    madgresso -i <file name> -w <new file name>

to replay `<file name>` before going into interactive mode again, saving any new
input to `<new file name>`.

You can replay multiple files

    madgresso <file name1> <file name2>

and combine it with `-i` too.


### Notes

Try not to disturb it, because inteferring can cause expected items to
disappear, which will cause the whole thing to crash.

Once it's done, it will leave you on the summary page, where you can save/submit
the claim after checking it over.
