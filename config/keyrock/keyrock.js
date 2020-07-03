var server_name = process.env.SERVER_NAME;
var database_host = (process.env.DATABASE_HOST) ? process.env.DATABASE_HOST : 'localhost';
var database_pass = (process.env.DATABASE_PASS) ? process.env.DATABASE_PASS : 'idm';
var smtp_user = process.env.SMTP_USER;
var smtp_pass = process.env.SMTP_PASS;

var config = {};

function to_boolean(env, default_value){
    return (env !== undefined) ? (env.toLowerCase() === 'true') : default_value;
}

function to_array(env, default_value){
    return (env !== undefined) ? env.split(',') : default_value;
}

config.host = 'https://' + server_name;
config.port = 3000

config.debug = to_boolean(process.env.IDM_DEBUG, true);

// HTTPS enable
config.https = {
    enabled: false,
    cert_file: 'certs/idm-2018-cert.pem',
    key_file: 'certs/idm-2018-key.pem',
    port: 443
};

// Config email list type to use domain filtering
config.email_list_type = null   // whitelist or blacklist

// Secret for user sessions in web
config.session = {
    secret: 'nodejs_idm',       // Must be changed
    expires: 60 * 60 * 1000     // 1 hour
}

// Key to encrypt user passwords
config.password_encryption = {
	key: 'nodejs_idm'		// Must be changed
}

// Enable CORS
config.cors = {
    enabled: to_boolean(process.env.IDM_CORS_ENABLED, false),
    options: {
        /* eslint-disable snakecase/snakecase */
        origin: to_array(process.env.IDM_CORS_ORIGIN, '*'),
        methods: to_array(process.env.IDM_CORS_METHODS, ['GET','HEAD','PUT','PATCH','POST','DELETE']),
        allowedHeaders: (process.env.IDM_CORS_ALLOWED_HEADERS || '*'),
        exposedHeaders: (process.env.IDM_CORS_EXPOSED_HEADERS || undefined),
        credentials: (process.env.IDM_CORS_CREDENTIALS || undefined),
        maxAge: (process.env.IDM_CORS_MAS_AGE || undefined),
        preflightContinue: (process.env.IDM_CORS_PREFLIGHT || false),
        optionsSuccessStatus: (process.env.IDM_CORS_OPTIONS_STATUS || 204)
        /* eslint-enable snakecase/snakecase */
    }
}

// Config oauth2 parameters
config.oauth2 = {
    authorization_code_lifetime: 5 * 60,            // Five minutes
    access_token_lifetime: 60 * 60,                 // One hour
    //access_token_lifetime: 60 * 60 * 60 * 146,      // One year
    refresh_token_lifetime: 60 * 60 * 24 * 14       // Two weeks
}

// Config api parameters
config.api = {
    token_lifetime: 60 * 60           // One hour
    //token_lifetime: 60 * 60 * 60 * 146  // One year
}

// Enable authzforce
config.authorization = {
    level: 'basic',
    authzforce: {
        enabled: false,
        host: '',
        port: 8080
    }
}

// Database info
config.database = {
    host: database_host,         // default: 'localhost' 
    password: 'idm',             // default: 'idm'
    username: 'root',            // default: 'root'
    database: 'idm',             // default: 'idm'
    dialect: 'mysql',            // default: 'mysql'
};

// External user authentication
config.external_auth = {
    enabled: false,
    authentication_driver: 'custom_authentication_driver',
    database: {
        host: 'localhost',
        database: 'db_name',
        username: 'db_user',
        password: 'db_pass',
        user_table: 'user',
        dialect: 'mysql'
    }
}

// Email configuration
config.mail = {
    host: 'SMTP-SERVER',
    port: 587,
    secure: false,
    auth: {
        user: smtp_user,
        pass: smtp_pass
    },
    from: smtp_user
}


// Config themes
config.site = {
    title: 'Identity Manager',
    theme: 'default'
};

// Config eIDAs Authentication
config.eidas = {
    enabled: false,
    gateway_host: 'localhost',
    idp_host: 'https://se-eidas.redsara.es/EidasNode/ServiceProvider',
    metadata_expiration: 60 * 60 * 24 * 365 // One year
}

// Enable usage control and configure the Policy Translation Point
 config.usage_control = {
 enabled: to_boolean(process.env.IDM_USAGE_CONTROL_ENABLED, false),
 ptp: {
 host: (process.env.IDM_PTP_HOST || 	'localhost'),
 port: (process.env.IDM_PTP_PORT || 8081),
 }
 }

module.exports = config;
