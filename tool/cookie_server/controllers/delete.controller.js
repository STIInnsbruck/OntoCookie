import SparqlClient from "sparql-http-client";

const endpointUrl =
  "https://smashhitactool.sti2.at/repositories/OntoCookie/statements";
const updateUrl = endpointUrl;
const user = "ontocookie";
const password = "ontocookie123456";

const client = new SparqlClient({ endpointUrl, updateUrl, user, password });

const deleteData = async (req, res) => {
  const userId = req.body.userId;

  const deleteUserCookiesQuery = `
  PREFIX : <http://www.semanticweb.org/OntoCookie#>
  PREFIX schema: <https://www.schema.org/>
  
  DELETE {
    ?s a <http://www.semanticweb.org/OntoCookie#Cookie> .
    } WHERE {
    ?s :userId :${userId}.}
    `;
  const deleteUserSessionCookiesQuery = `
    PREFIX : <http://www.semanticweb.org/OntoCookie#>
    PREFIX schema: <https://www.schema.org/>
    
    DELETE {
      ?s a <http://www.semanticweb.org/OntoCookie#SessionCookie> .
      } WHERE {
      ?s :userId :${userId}.}
      `;

  await deleteDataFromKnowledgeGraph(deleteUserCookiesQuery);
  await deleteDataFromKnowledgeGraph(deleteUserSessionCookiesQuery);
  res.status(200).json({ message: "Cookies deleted successfully!" });
};

async function deleteDataFromKnowledgeGraph(deleteUserCookiesQuery) {
  await client.query.update(deleteUserCookiesQuery);
}

export { deleteData };
