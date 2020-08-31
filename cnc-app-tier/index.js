const express = require('express');
const request = require('request');
const CircularJSON = require('circular-json');
const fs = require('fs');

// https://www.npmjs.com/package/postgres-pool?activeTab=readme
// const { Pool } = require('postgres-pool');

const {
    Pool,
    client
} = require('pg');

const app = express();
const port = 3000;

const pool = new Pool({
    // connectionString: "postgres://postgres:postgres@localhost:54320/postgres"
    // connectionString: "postgres://postgres:adminpass@mel-cluster.cluster-ctwpahokgiiz.ap-southeast-2.rds.amazonaws.com/dbname"
    connectionString: "postgres://postgres:adminpass@db-tier-auroradbcluster-19agh61sih9lq.cluster-ctwpahokgiiz.ap-southeast-2.rds.amazonaws.com:5432/gisdata?sslmode=verify-full",
    // ssl: 'aws-rds'
    ssl: {
        rejectUnauthorized: false,
        ca: fs.readFileSync(`${__dirname}/certs/rds-ca-2019-root.pem`),
    }
});

// express-healthcheck: respond on /health route for LB checks
app.use('/health', require('express-healthcheck')());

app.get( '/', (req, res, next) => {
    res.send( "Geoserver is up and running." );
});

app.get( '/data', async function(req, res, next) {
    console.log("Processing request " + CircularJSON.stringify(req));
    // SELECT inet_server_addr();


    pool.query('select name, region from country limit 300', [], (err, result) => {
        if (err) {
            console.log("Error result " + JSON.stringify(err));
            return res.status(405).jsonp({
                error: err
            });
        }

        console.log("Processing result " + JSON.stringify(result.rows));

        console.log("Processing result " + JSON.stringify(result.rows));
        return res.status(200).jsonp({
            data: result.rows
        });
    });
});

app.listen(port, () => console.log(`Geoserver app listening on port ${port}!`))




