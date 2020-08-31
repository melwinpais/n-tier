const express = require('express');
const request = require('request');
const CircularJSON = require('circular-json');
const querystring = require('querystring');


const {
    Pool,
    client
} = require('pg');

const app = express();
const port = 3001;

const pool = new Pool({
    // connectionString: "postgres://postgres:postgres@localhost:54320/postgres"
    connectionString: "postgres://postgres:adminpass@mel-cluster.cluster-ctwpahokgiiz.ap-southeast-2.rds.amazonaws.com/dbname"
    // connectionString: encodeURIComponent("postgres://postgres:adminpass@mel-cluster.cluster-ctwpahokgiiz.ap-southeast-2.rds.amazonaws.com:5432/public?ssl=true")
});

// var client = new pg.Client(conString);
// client.connect();

// express-healthcheck: respond on /health route for LB checks
app.use('/health', require('express-healthcheck')());

app.get( '/', (req, res, next) => {
    res.send( "Geoserver is up and running." );
});

app.get( '/data', async function(req, res, next) {
    console.log("Processing request " + CircularJSON.stringify(req));

    pool.query('select * from public.country limit 3', [], (err, result) => {
        if (err) {
            console.log("Error result " + JSON.stringify(err));

            return res.status(405).jsonp({
                error: err
            });
        }
        console.log("Processing result " + JSON.stringify(result));
        return res.status(200).jsonp({
            data: result.rows
        });
    });
});

app.listen(port, () => console.log(`Geoserver app listening on port ${port}!`))




