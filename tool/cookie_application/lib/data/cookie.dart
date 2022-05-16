class Cookie {

  final String domain;
  final double expirationDate;
  final bool hostOnly;
  final bool httpOnly;
  final String name;
  final String path;
  final String sameSite;
  final bool secure;
  final bool session;
  //storeId ignored - currently unknown what type storeId is, the examples are all NULL


  const Cookie({
    this.domain,
    this.expirationDate,
    this.hostOnly,
    this.httpOnly,
    this.name,
    this.path,
    this.sameSite,
    this.secure,
    this.session
  });

  factory Cookie.fromJson(Map<String, dynamic> json) {
    return Cookie(
      domain: json['domain'] as String,
      expirationDate: json['expirationDate'] as double,
      hostOnly: json['hostOnly'] as bool,
      httpOnly: json['httpOnly'] as bool,
      name: json['name'] as String,
      path: json['path'] as String,
      sameSite: json['sameSite'] as String,
      secure: json['secure'] as bool,
      session: json['session'] as bool
    );
  }

  factory Cookie.fromJsonWeb(Map<String, dynamic> json) {
    //Expiration date can be an undefined.
    String expirationDate = "0";
    if(json['expires'] != null) {
      expirationDate = json['expires'].toString().replaceAll("http://www.semanticweb.org/OntoCookie#", "");
      if(expirationDate.compareTo("undefined") == 0) {
        expirationDate = "0";
      }
    }

    return Cookie(
        domain: json['domain'].toString().replaceAll("http://www.semanticweb.org/OntoCookie#", ""),
        expirationDate: double.parse(expirationDate),
        name: json['name'].toString().replaceAll("http://www.semanticweb.org/OntoCookie#", "")
    );
  }
}