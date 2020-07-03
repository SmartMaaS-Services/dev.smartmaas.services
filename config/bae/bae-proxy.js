var config = {};

// The PORT used by
config.port = 8004;
config.host = 'bae';

config.proxy = {
    enabled: true,
    host: 'market.DOMAIN_NAME',
    secured: true,
    port: 443
};

// Set this var to undefined if you don't want the server to listen on HTTPS
config.https = {
    enabled: false,
    certFile: 'cert/cert.crt',
    keyFile: 'cert/key.key',
    caFile: 'cert/ca.crt',
    port: 443
};

// Express configuration
config.proxyPrefix = '';
config.portalPrefix = '';
config.logInPath = '/login';
config.logOutPath = '/logOut';
config.sessionSecret = 'keyboard cat';
config.theme = '';

// OAuth2 configuration
config.oauth2 = {
    'server': 'https://accounts.DOMAIN_NAME/',
    'clientID': 'BAE_ID',
    'clientSecret': 'BAE_SECRET',
    'callbackURL': 'https://market.DOMAIN_NAME/auth/fiware/callback',
    'isLegacy': false,
    'roles': {
        'admin': 'admin',
        'customer': 'customer',
        'seller': 'seller',
        'orgAdmin': 'orgAdmin'
    }
};


// Customer Role Required to buy items
config.customerRoleRequired = false;

// MongoDB
config.mongoDb = {
    server: 'mongo',
    port: 27017,
    user: '',
    password: '',
    db: 'baeproxy'
};

// Configure endpoints
config.endpoints = {
    'management': {
        'path': 'management',
        'host': 'localhost',
        'port': config.port,
        'appSsl': config.https.enabled
    },
    'catalog': {
        'path': 'DSProductCatalog',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'ordering': {
        'path': 'DSProductOrdering',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'inventory': {
        'path': 'DSProductInventory',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'charging': {
        'path': 'charging',
        'host': 'charging.bae.docker',
        'port': '8006',
        'appSsl': false
    },
    'rss': {
        'path': 'DSRevenueSharing',
        'host': 'bae_rss',
        'port': '8080',
        'appSsl': false
    },
    'party': {
        'path': 'DSPartyManagement',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'billing':{
        'path': 'DSBillingManagement',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'customer': {
        'path': 'DSCustomerManagement',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'usage':  {
        'path': 'DSUsageManagement',
        'host': 'bae_apis',
        'port': '8080',
        'appSsl': false
    },
    'sla': {
        'path': 'SLAManagement',
        'host': 'localhost',
        'port': config.port,
        'appSsl': false
    },
    'reputation': {
        'path': 'REPManagement',
        'host': 'localhost',
        'port': config.port,
        'appSsl': false
    }
};

// Percentage of the generated revenues that belongs to the system
config.revenueModel = 30;

// Tax rate
config.taxRate = 20;

// Billing Account owner role
config.billingAccountOwnerRole = 'bill receiver';

// list of paths that will not check authentication/authorization
// example: ['/public/*', '/static/css/']
config.publicPaths = [];

config.indexes = {
    'engine': 'elasticsearch', // local or elasticsearch
    'elasticHost': 'bae_elasticsearch:9200'
};

config.magicKey = undefined;

module.exports = config;
