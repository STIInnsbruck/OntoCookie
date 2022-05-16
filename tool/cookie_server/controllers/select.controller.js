import SparqlClient from "sparql-http-client";

const endpointUrl = "https://smashhitactool.sti2.at/repositories/OntoCookie";
const user = "ontocookie";
const password = "ontocookie123456";

const client = new SparqlClient({ endpointUrl, user, password });

const getData = async (req, res) => {
  const userId = req.body.userId;

  let selectCookieQuery = `
      PREFIX : <http://www.semanticweb.org/OntoCookie#>
        select * where { 
          ?s :userId :${userId} .
          ?s :dateCreated ?dateCreated .
          ?s :hasDomain ?domain .
          ?s :name ?name .
          ?s :userId ?userId .
          OPTIONAL { ?s  :expires  ?expires } .
          } ORDER BY ASC(?expires)
      `;

  const stream = await client.query.select(selectCookieQuery);

  var cookieArray = [];
  var cookieObject = {
    expires: String,
    s: String,
    dateCreated: String,
    domain: String,
    name: String,
    userId: String,
  };

  stream.on("data", (row) => {
    Object.entries(row).forEach(([key, value]) => {
      if (cookieObject.hasOwnProperty(key)) {
        cookieObject[key] = value.value;
      } else {
        cookieObject[key] = 0;
      }
    });

    cookieArray.push(Buffer.from(JSON.stringify(cookieObject) + "00SxW7"));
  });

  stream.on("error", (err) => {
    res.status(500).send(err);
  });

  stream.on("end", () => {
    const result = Buffer.concat(cookieArray).toString("utf8");
    const myarr = result.split("00SxW7");
    var cookieResArray = [];
    for (let index = 0; index < myarr.length - 1; index++) {
      cookieResArray.push(JSON.parse(myarr[index]));
    }
    res.status(200).send(cookieResArray);
  });
};

export { getData };
