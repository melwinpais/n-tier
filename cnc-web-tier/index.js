const express = require('express');
const request = require('request');

const app = express();
const port = 3000;
const restApiUrl = process.env.GEOSERVER_URL;

// express-healthcheck: respond on /health route for LB checks
app.use('/health', require('express-healthcheck')());

app.get( '/', (req, res, next) => {
    res.send( "All good." );
});

console.log('The env variables are :', process.env);
app.get('/data/', function(req, res) {
    request(
        restApiUrl, {
            method: "GET",
        },
        function(err, resp, body) {
            if (!err && resp.statusCode === 200) {
                var objData = JSON.parse(body);
                var c_cap = objData.data;
                var responseString = `<table border="1"><tr><td>Country</td><td>Region</td></tr>`;

                for (var i = 0; i < c_cap.length; i++)
                    responseString = responseString +
                      `<tr><td>${c_cap[i].name}</td><td>${c_cap[i].region}</td></tr>`;

                responseString = responseString + `</table>`;
                res.send(responseString);
            } else {
                console.log(err);
                res.send(`<!DOCTYPE html><html><body><h1>Something went wrong.</h1><p>Please try again later.</p></body></html>`)
            }
        });
});

app.listen(port, () => console.log(`Frontend app listening on port ${port}!`))