
# Agresso URL
AGRESSO_URL = 'https://myagresso.mycompany.co.uk'

# Agresso username
USERNAME = 'xxxx000'

# Agresso password -- storing your password here in plaintext is a bad idea.
# Retreiving your password via a password manager shell command in backticks
# is recommended.  When set to nil the user must enter the password manually
#   PASSWORD = `/home/madgresso/.config/madgresso/getpass.sh`
PASSWORD = nil

# set proxy = nil for no proxy or a string accepted by --proxy-server in Chrome
# otherwise:
#   PROXY = 'socks5://localhost:8080'
PROXY = nil

# Expense items without an explicit account code use this one.
# Use nil if you want to accept the aggresso default
#   DEFAULT_ACCOUNT = '6090'
DEFAULT_ACCOUNT = nil

# Expense items without an explicit sub-project use this one.
DEFAULT_SUBPROJ = 'R10101-01'

# Expense types maps shortcuts to the full description given on agresso.  Some
# examples are filled in.
EXPENSE_TYPES = {
    'reg' => 'Conference Fees - Currency',
    'hotel' => 'Hotel Room - Currency',
    'food' => 'Meals & Refreshments - Currency',
    'plane' => 'Airfares - International - Currency',
    'train' => 'Public Transport - Train - Currency',
    'bike' => 'Mileage - Bicycle rate'
    'bus' => 'Public Transport - Other - Currency'
}
