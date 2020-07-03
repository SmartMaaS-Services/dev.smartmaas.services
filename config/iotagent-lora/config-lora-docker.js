var config = {};

config.iota = {
    logLevel: 'DEBUG',
    timestamp: true,
    contextBroker: {
        host: 'orion',
        port: '1026',
        ngsiVersion: 'v2'
    },

    server: {
        port: 4061
    },

    defaultResource: '/iot/d',

    deviceRegistry: {
        type: 'mongodb'
    },

    mongodb: {
        host: 'mongo',
        port: '27017',
        db: 'iotagentlora'
    },

    types: {},

    service: 'howtoService',

    subservice: '/howto',

    providerUrl: 'http://localhost:4061',

    deviceRegistrationDuration: 'P1Y',

    defaultType: 'Thing'
};

module.exports = config;
