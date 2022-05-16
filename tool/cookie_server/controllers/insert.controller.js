import SparqlClient from "sparql-http-client";

const endpointUrl =
  "https://smashhitactool.sti2.at/repositories/OntoCookie/statements";
const updateUrl = endpointUrl;
const user = "ontocookie";
const password = "ontocookie123456";

const client = new SparqlClient({ endpointUrl, updateUrl, user, password });

const annotate = (req, res) => {
  const cookies = req.body;

  var today = new Date();
  var date =
    today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate();

  const insertUserQuery = `
      PREFIX : <http://www.semanticweb.org/OntoCookie#>
      PREFIX schema: <https://www.schema.org/>

      INSERT DATA {:${cookies[0].userId} a <https://www.schema.org/Person>;
            schema:identifier :${cookies[0].userId}.}
      `;

  insertDataInKnowledgeGraph(insertUserQuery);

  for (let index = 0; index < cookies.length; index++) {
    const element = cookies[index];
    let element_domain = element.domain;
    if (element_domain[0] === ".") {
      element_domain = "";
      for (let j = 1; j < element.domain.length; j++) {
        element_domain += element.domain[j];
      }
    }

    let cookieName = `Cookie_${element.userId}_${today.getTime()}_${index}`;

    let insertCookieQuery;
    if (JSON.parse(element.session) == true || element.expirationDate == undefined) {
      insertCookieQuery = `
        PREFIX : <http://www.semanticweb.org/OntoCookie#>
    
        INSERT DATA {:${cookieName} a <http://www.semanticweb.org/OntoCookie#SessionCookie>;
               :dateCreated :${date};
               :hasDomain :${element_domain};
               :name :${element.name} ;
               :userId :${element.userId};.}
        `;
    } else {
      insertCookieQuery = `
        PREFIX : <http://www.semanticweb.org/OntoCookie#>
    
        INSERT DATA {:${cookieName} a <http://www.semanticweb.org/OntoCookie#Cookie>;
               :dateCreated :${date};
               :expires :${element.expirationDate};
               :hasDomain :${element_domain};
               :name :${element.name} ;
               :userId :${element.userId};.}
        `;
    }

    insertDataInKnowledgeGraph(insertCookieQuery);
  }

  res.status(200).json({ message: "Cookies inserted successfully!" });
};

async function insertDataInKnowledgeGraph(insertCookieQuery) {
  const stream = await client.query.update(insertCookieQuery);
}

export { annotate };
