# Expense claim class, created from file of format (lines can be any order).
# All lines are optional.
#
#   Receipts: <path to pdf of receipts> [default value: don't add receipts]
#   Project: <subproject code to override default>
#   Comment: <change the comment to override the default>
#   Month: <change the month/year field to override the default>
#
# Expense item rows are of the three possible formats
#
#   <type>; <date>; <cur> <amount>; <desc>
#   <type>; <date>; <cur> <amount>; <account>; <desc>
#   <type>; <date>; <cur> <amount>; <account>; <sub-project>; <desc>
#
# E.g.
#
#   plane; 12 Oct; GBP 100; Item 1: My flight to Singapore
#   plane; 12 Oct; GBP 100; 6050; Item 1: My flight to Singapore
#   plane; 12 Oct; GBP 100; 6050; R10101-01; Item 1: My flight to Singapore
#
# <cur> is given as a 3-char currency code followed by the value.  If this is
# empty then the default currency given by Agresso will be accepted.  For
# mileage, use the code MIL and the amount is the number of miles.  E.g.
#
#   bike; 12 Oct; MIL 13; Item 1: My cycle to Paddington and back
#
# The <account> is the account code (e.g. 6050 for staff travel).  The default
# value is defined in the configuration file.
#
# The <subproject> is the subproject code (e.g. R10101-01).  The default is
# defined in the configuration file.
#
# The <date> can be given in any format ruby is happy with.  Missing values are
# filled in with the current value.  E.g. '12 Oct' is read as '12 Oct 2016' (if
# the program is being run on e.g. 25 Nov 2016).
#
# Valid <type>s are defined in configuration.rb
#
# Rows starting with '#' are ignored.


MILEAGE_CODE = 'MIL'

# Gettable attributes:
#  +type+:: string, EXPENSE_TYPES key identifying type of the expense
#  +date+:: ruby Time, claim date
#  +currency+:: string, 3-letter currency code
#  +amount+:: string, the amount of the claim
#  +description+:: string, the description including item number
#  +subproject+:: string, the sub project
#  +account+:: string, the account or nil if agresso default is to be accepted
class ExpenseItem
    attr_reader :type,
                :date,
                :currency,
                :amount,
                :description,
                :account,
                :subproject

    # Params:
    #  +type+:: string, EXPENSE_TYPES key identifying the type of the expense
    #  +date+:: string, date in ruby recognisable format
    #  +currency+:: string, 3-letter currency code
    #  +amount+:: string, the amount of the claim
    #  +description+:: string, the description including item number
    #  +subproject+:: string, the sub project
    #  +account+:: string, the account
    def initialize(type,
                   date,
                   currency,
                   amount,
                   description,
                   account,
                   subproject)
        @type = type
        @date = Time.parse date
        @currency = currency
        @amount = amount
        @description = description
        @subproject = subproject
        @account = account
    end

    def to_s()
        return "type: #{type}\n" +
               "date: #{date.strftime('%d/%m/%Y')}\n" +
               "currency: #{currency}\n" +
               "amount: #{amount}\n" +
               "description: #{description}\n" +
               "subproject: #{subproject}\n" +
               "account: #{account}\n"
    end
end


# Expense read from file, items are processed as they are read, hence receipts,
# month, and comment attributes will not be "final" until all items have been
# read.
#
# Readable attributes
#  +receipts+:: string, path to receipts file or nil if none
#  +items+:: array of ExpenseItems read from file
#  +month+:: latest identified value for month/year field, nil if none specified
#  +comment+:: latest identified value for comment field, nil if none specified
class Expenses
    attr_reader :receipts,
                :items,
                :month,
                :comment

    # Reads new expenses object from file name
    # Params:
    #  +input_stream+:: a stream of input characters, e.g. and open file or
    #                   $stdin.  Can also be an array of input streams (read one
    #                   after another)
    #  +default_account+:: string, the default account code from configuration
    #  +default_subproject+:: string, the default subproject from configuration
    def initialize(input_streams,
                   default_account,
                   default_subproject)
        @month = nil
        @comment = nil
        @receipts = []

        if not input_streams.kind_of?(Array)
            input_streams = [input_streams]
        end

        @items = Enumerator.new do |items|
            @field_matcher = [
                [/^#.*/, lambda { |m| }],
                [/^Receipts:\s*(.*)$/i, lambda { |m|
                    Dir.glob(m[1].chomp.strip) do |filename|
                        @receipts << filename
                        puts "Added receipt #{filename}"
                    end
                }],
                [/^Project:\s*(.*)$/i, lambda { |m| default_subproject = m[1] }],
                [/^Month:\s*(.*)$/i, lambda { |m| @month = m[1] }],
                [/^Comment:\s*(.*)$/i, lambda { |m| @comment = m[1] }],
                [/^(\w+);\s*([^;]+);\s*(\w*)\s+([\d.]+);\s([^;]*)$/,
                 lambda { |m|
                    items << ExpenseItem.new(m[1], m[2], m[3], m[4], m[5].chomp,
                                             default_account,
                                             default_subproject)
                 }],
                [/^(\w+);\s*([^;]+);\s*(\w{3})\s+([\d.]+);\s*(\d{4});\s*([^;]*)$/,
                 lambda { |m|
                    items << ExpenseItem.new(m[1], m[2], m[3], m[4], m[6].chomp,
                                             m[5], default_subproject)
                 }],
                [/^(\w+);\s*([^;]+);\s*(\w{3})\s+([\d.]+);\s*(\d{4});\s*([\w-]+);\s*([^;]*)$/,
                 lambda { |m|
                    items << ExpenseItem.new(m[1], m[2], m[3], m[4], m[7].chomp,
                                             m[5], m[6])
                 }]
            ]

            input_streams.each do |input_stream|
                input_stream.each_line do |line|
                    if line.chomp.strip.length == 0
                        next
                    end

                    matched = false
                    @field_matcher.each do |re, handler|
                        m = re.match(line)
                        if not m.nil?
                            handler.call(m)
                            matched = true
                            break
                        end
                    end

                    if not matched
                        $stdout.puts "Ignoring line #{line}"
                    end
                end
            end
        end
    end


end
