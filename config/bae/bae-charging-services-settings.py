from __future__ import unicode_literals

VERIFY_REQUESTS = True

SITE = 'https://market.DOMAIN_NAME'
LOCAL_SITE = 'http://charging.bae.docker:8006/'

CATALOG = 'http://bae_apis:8080/DSProductCatalog'
INVENTORY = 'http://bae_apis:8080/DSProductInventory'
ORDERING = 'http://bae_apis:8080/DSProductOrdering'
BILLING = 'http://bae_apis:8080/DSBillingManagement'
USAGE = 'http://bae_apis:8080/DSUsageManagement'

RSS = 'http://bae_rss:8080/DSRevenueSharing'

AUTHORIZE_SERVICE = 'http://bae:8004/authorizeService/apiKeys'
