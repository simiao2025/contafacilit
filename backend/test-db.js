const { Client } = require('pg');

const client = new Client({
    connectionString: "postgresql://admin:password@127.0.0.1:5432/contafacilit",
});

client.connect()
    .then(() => {
        console.log('Connected successfully');
        process.exit(0);
    })
    .catch(err => {
        console.error('Connection error', err.stack);
        process.exit(1);
    });
