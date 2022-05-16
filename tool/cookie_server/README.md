# NodeJS Cookie Server

## Requirements
- npm
- express (npm install express)
- http (npm install http)
- body-parser (npm install body-parser)
- cors (npm install cors)
- sparql-http-client (npm install sparql-http-client)

## How to Run
### Start Server
Type in command >'npm start'

Open browser at '127.0.0.1:58080'

### Call Queries
Currently only the select query is implemented, I didn't get much time to get the others going yet.
#### SELECT QUERY
'127.0.0.1/get'

This should do the job. BUT there is currently no feedback to the client. In your server console you will see the result.
