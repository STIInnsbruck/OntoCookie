import 'dart:io';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cookie_consent_vis/data/cookie.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:cookie_consent_vis/data/web_data_provider.dart';

class OverviewPage extends StatefulWidget {

  String title;
  String cookiesJson;
  String userId;

  List<charts.Series> barSeriesList;
  List<charts.Series> doughnutSeriesList;
  List<charts.Series> lineSeriesList;
  bool animate;
  bool archiveData;

  OverviewPage(var cookiesJson, String userId, bool archiveData) {
    this.title = "Cookie Overivew";
    this.animate = true;
    this.cookiesJson = cookiesJson;
    this.userId = userId;
    this.archiveData = archiveData;
  }

  /**factory OverviewPage.withSampleData() {
    return new OverviewPage("Cookie Overview", _createBarSampleData(), _createDoughnutSampleData(), _createLineSampleData(), this.cookiesJson, animate: true);
  }*/

  /// Create one series with sample hard coded data.
  static List<charts.Series<OrdinalSales, String>> _createBarSampleData() {
    final data = [
      new OrdinalSales('2014', 5),
      new OrdinalSales('2015', 25),
      new OrdinalSales('2016', 100),
      new OrdinalSales('2017', 75),
    ];

    return [
      new charts.Series<OrdinalSales, String>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createDoughnutSampleData() {
    final data = [
      new LinearSales(0, 100),
      new LinearSales(1, 75),
      new LinearSales(2, 25),
      new LinearSales(3, 5),
    ];

    return [
      new charts.Series<LinearSales, int>(
        id: 'Sales',
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createLineSampleData() {
    final data = [
      new LinearSales(0, 5),
      new LinearSales(1, 25),
      new LinearSales(2, 100),
      new LinearSales(3, 75),
    ];

    return [
      new charts.Series<LinearSales, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {

  WebDataProvider webDataProvider = new WebDataProvider();

  List<Cookie> cookieList = [];
  String mostCookiesSite;
  String leastCookiesSite;
  Cookie longestCookie = Cookie();
  Cookie shortestCookie = Cookie();
  String mostCookies;
  String leastCookies;
  int numberOfCookies = 0;
  Future<List<charts.Series>> doughnutSeriesList;
  Future<List<charts.Series>> lineSeriesList;
  bool _loading = true;


  Future<void> _getExampleCookies() async {
    cookieList.clear();
    //String jsonString = await rootBundle.loadString('resources/data/cookie_netf_example.json');
    String jsonString = widget.cookiesJson;
    jsonString = jsonString.replaceAll(".www", "");
    jsonString = jsonString.replaceAll("www.", "");
    jsonString = jsonString.replaceAll(".google.com", "google.com");
    jsonString = jsonString.replaceAll(".euronews.com", "euronews.com");
    jsonString = jsonString.replaceAll(".bbc.com", "bbc.com");
    jsonString = jsonString.replaceAll("en.wikipedia.org", "wikipedia.org");
    jsonString = jsonString.replaceAll(".wikipedia.org", "wikipedia.org");
    List<dynamic> body = json.decode(jsonString);
    setState(() {
      cookieList = body.map((dynamic item) => Cookie.fromJson(item)).toList();
    });
    shortestCookie = _getShortestCookie(cookieList);
    longestCookie = _getLongestCookie(cookieList);
    numberOfCookies = _countCookies(cookieList);
    doughnutSeriesList = generateDoughnutData(cookieList);
    lineSeriesList = generateLineData(cookieList);
  }

  Future<void> _getDownloadedCookies() async {
    await webDataProvider.insertCookies(widget.cookiesJson);
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loading = false;
    });

    cookieList.clear();
    List<Cookie> cookies = await webDataProvider.selectCookies(widget.userId);
    setState(() {
      cookieList = cookies;
    });
    shortestCookie = _getShortestCookie(cookieList);
    longestCookie = _getLongestCookie(cookieList);
    numberOfCookies = _countCookies(cookieList);
    doughnutSeriesList = generateDoughnutData(cookieList);
    lineSeriesList = generateLineData(cookieList);
  }

  @override
  initState() {
    super.initState();
    //webDataProvider.selectCookies();
    if(widget.archiveData == true) {
      _getDownloadedCookies();
    } else {
      setState(() {
        _getExampleCookies();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return isBigScreen(screenWidth)
        ? bigScreenBuild(screenWidth, screenHeight)
        : smallScreenBuild(screenWidth, screenHeight);
  }

  ///We consider anything above 500 in width a big screen.
  bool isBigScreen(double width) {
    if (width <= 500.0) {
      return false;
    } else {
      return true;
    }
  }

  ///Function to build the screen when a big screen is given. Placing most
  ///UI elements horizontally.
  Widget bigScreenBuild(double screenWidth, double screenHeight) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height:10),
          Text("Your ID: ${widget.userId}"),
          Row(
            children: [
              bigScreenDomainList(screenHeight, screenWidth),
              Column(
                children: [
                  FutureBuilder(
                    future: generateLineData(cookieList),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return bigScreenDurationBarChart(screenHeight, screenWidth, snapshot.data);
                      } else {
                        return CircularProgressIndicator();
                      }
                    }
                  ),
                  FutureBuilder(
                    future: generateDoughnutData(cookieList),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return bigScreenDoughnutChart(screenHeight, screenWidth, snapshot.data);
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          Container(height: 30),
          bigScreenCookieFacts()
        ],
      ),
    );
  }

  ///Function to build the screen when a small screen is given. Placing the UI
  ///elements in a scrollable vertical view.
  Widget smallScreenBuild(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth,
      height: screenHeight,
      child: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            smallScreenBarChart(screenHeight, screenWidth),
            smallScreenLineChart(screenHeight, screenWidth),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                smallScreenDoughnutChart(screenHeight, screenWidth),
                smallScreenDoughnutChart(screenHeight, screenWidth),
              ],
            ),
            Container(height: 30),
            smallScreenCookieFacts()
          ],
        ),
      ),
    );
  }

  Widget bigScreenCookieFacts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Website with the most cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
              _loading == true
                  ? Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
              : Text("$mostCookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Website with the least cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
              _loading == true
                  ? Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
              : Text("$leastCookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Website with the longest cookie:", style: TextStyle(fontSize: 15), maxLines: 2),
              _loading == true
                  ? Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
              : Text("${longestCookie.domain}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Website with the shortest cookie:", style: TextStyle(fontSize: 15), maxLines: 2),
              _loading == true
                  ? Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
              : Text("${shortestCookie.domain}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Total amount of cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
              _loading == true
                  ? Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
              : Text("$numberOfCookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
            ],
          ),
        ),
        FutureBuilder(
          future: generateDoughnutData(cookieList),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Average duration of cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
                    Text("${calcAverageDurationInDays(cookieList)} Day(s)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30), maxLines: 1)
                  ],
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
        widget.archiveData ?
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Withdraw consent & erase data", style: TextStyle(fontSize: 15), maxLines: 2),
              MaterialButton(
                  onPressed: () {
                    showDeleteDialog();
                  },
                  child: Icon(Icons.delete_forever, color: Colors.red, size: 45)
              )
            ],
          ),
        ) : SizedBox(height: 0, width: 0),
      ],
    );
  }

  Widget bigScreenBarChart(double height, double width) {
    return Container(
      padding: EdgeInsets.all(20),
      height: height * 0.66,
      width: width * 0.5,
      child: charts.BarChart(widget.barSeriesList, animate: widget.animate),
    );
  }

  Widget bigScreenDomainList(double height, double width) {
    return Container(
       padding: EdgeInsets.all(20),
       height: height * 0.80,
       width: width * 0.5,
       child: Column(
         children: [
           listHeader(),
           Expanded(
               child: ListView.separated(
                 physics: BouncingScrollPhysics(),
                 separatorBuilder: (context, index) => Divider(
                   color: Colors.grey,
                   height: 0,

                 ),
                   itemCount: cookieList.length,
                   itemBuilder: (BuildContext context, int index) {
                     bool expand = false;
                     return cookieStatisticsTile(width * 0.5, height * 0.05, index, expand, cookieList);
                   }
               )
           )
         ],
       )
    );
  }

  Widget bigScreenDurationBarChart(double height, double width, var data) {
    final staticTicks = <charts.TickSpec<String>> [
      charts.TickSpec("< 1 Day"),
      charts.TickSpec("< 1 Week"),
      charts.TickSpec("< 1 Month"),
      charts.TickSpec("< 1 Year"),
      charts.TickSpec("< 10 Years"),
      charts.TickSpec("10+ Years"),

    ];

    return Container(
      padding: EdgeInsets.all(20),
      height: height * 0.40,
      width: width * 0.50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: charts.BarChart(data, animate: widget.animate, domainAxis: charts.OrdinalAxisSpec(
            tickProviderSpec: charts.StaticOrdinalTickProviderSpec(staticTicks)
          ))),
          Text("Cookies Based on their duration")
        ],
      )
    );
  }

  Widget bigScreenDoughnutChart(double height, double width, var data) {
    return Container(
      padding: EdgeInsets.all(20),
      height: height * 0.40,
      width: width * 0.50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: charts.PieChart(data,
              animate: widget.animate,
              defaultRenderer: new charts.ArcRendererConfig(
                  arcWidth: 60,
                  arcRendererDecorators: [charts.ArcLabelDecorator()]))),
          Text("Cookie distribution between websites")
        ],
      )
    );
  }

  Widget smallScreenBarChart(double height, double width) {
    return Container(
      padding: EdgeInsets.all(20),
      height: height * 0.66,
      child: charts.BarChart(widget.barSeriesList, animate: widget.animate),
    );
  }

  Widget smallScreenLineChart(double height, double width) {
    return Container(
        padding: EdgeInsets.all(20),
        height: height * 0.66,
        child: charts.LineChart(widget.lineSeriesList, animate: widget.animate, defaultRenderer: new charts.LineRendererConfig(includePoints: true))
    );
  }

  Widget smallScreenDoughnutChart(double height, double width) {
    return Container(
        padding: EdgeInsets.all(20),
        height: height * 0.66,
        width: width * 0.5,
        child: charts.PieChart(widget.doughnutSeriesList, animate: widget.animate, defaultRenderer: new charts.ArcRendererConfig(arcWidth: 60))
    );
  }

  Widget smallScreenCookieFacts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Website with the most cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
                  Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40), maxLines: 1)
                ],
              ),
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Website with the least cookies:", style: TextStyle(fontSize: 15), maxLines: 2),
                  Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40), maxLines: 1)
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Website with the longest cookie:", style: TextStyle(fontSize: 15), maxLines: 2),
                  Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40), maxLines: 1)
                ],
              ),
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Website with the shortest cookie:", style: TextStyle(fontSize: 15), maxLines: 2),
                  Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40), maxLines: 1)
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Total amount of cookies:", style: TextStyle(fontSize: 20), maxLines: 2),
                  Text("24", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40), maxLines: 1)
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  ListTile listHeader() {
    return ListTile(
      title: Row(
        children: [
          Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: Text("#"))),
          Expanded(flex: 2,child: Text("Cookie Source")),
          Spacer(flex: 1),
          Expanded(flex: 2, child: Text("Cookie Type")),
          Spacer(flex: 1),
          Expanded(flex: 2, child: Text("Cookie Name")),
          Spacer(flex: 1),
          Expanded(flex: 2, child: Text("Cookie Duration"))
        ],
      ),
    );
  }

  Widget cookieStatisticsTile(double width, double height, int index, bool expand, List<Cookie> list) {

    Duration duration;
    if (list[index].expirationDate != null && list[index].expirationDate != 0) {
      duration = Duration(milliseconds: durationFromToday(list[index].expirationDate.toInt() * 1000));
    } else {
      duration = Duration(milliseconds: 0);
    }
    return MaterialButton(
        hoverColor: Colors.grey[200],
        onPressed: () {
          expand =! expand;
        },
        child: ListTile(
          title: Row(
            children: [
              Expanded(flex: 1, child: Text("${index+1}.")),
              Expanded(flex: 2, child: Text("${list[index].domain}")),
              Spacer(flex: 1),
              Expanded(flex: 2, child: duration.inHours == 0? Text("[Session Cookie]") : Text("[Other Cookie]")),
              Spacer(flex: 1),
              Expanded(flex: 2, child: Text("${list[index].name}")),
              Spacer(flex: 1),
              Flexible(flex: 2, child: duration.inDays < 0? Text("EXPIRED", style: TextStyle(color: Colors.red)) : Text("${duration.inDays} Day(s)"))
            ],
          )
        )
    );
  }

  int _countCookies(List<Cookie> list) {
    return list.length;
  }

  int calcAverageDurationInDays(List<Cookie> list) {

    int sumDurations = 0;
    double avg = 0;

    for (int i = 0; i < list.length; i++) {
      Duration duration;
      if (list[i].expirationDate != null && list[i].expirationDate != 0) {
      duration = Duration(milliseconds: durationFromToday(list[i].expirationDate.toInt() * 1000));
      } else {
      duration = Duration(milliseconds: 0);
      }
      sumDurations += duration.inMilliseconds;
    }
    avg = sumDurations / list.length;

    Duration avgDuration = Duration(milliseconds: avg.toInt());
    return avgDuration.inDays;
  }

  Cookie _getShortestCookie(List<Cookie> list) {
    Cookie shortestCookie = list[0];
    for (int i = 0; i < list.length; i++) {
      if(shortestCookie.expirationDate == null || list[i].expirationDate == null) {
        continue;
      } else {
        if(shortestCookie.expirationDate > list[i].expirationDate) {
          shortestCookie = list[i];
        }
      }
    }
    return shortestCookie;
  }

  Cookie _getLongestCookie(List<Cookie> list) {
    Cookie longestCookie = list[0];
    for (int i = 0; i < list.length; i++) {
      if(longestCookie.expirationDate == null || list[i].expirationDate == null) {
        continue;
      } else {
        if(longestCookie.expirationDate < list[i].expirationDate) {
          longestCookie = list[i];
        }
      }
    }
    return longestCookie;
  }

  Future<List<charts.Series>> generateDoughnutData(List<Cookie> list) async {
    Map map = Map();

    list.forEach((element) {
      if(!map.containsKey(element.domain)) {
        map[element.domain] = 1;
      } else {
        map[element.domain] += 1;
      }
    });

    List<WebsiteData> data = [];


    int maxCookieCount = map.values.first;
    int minCookieCount = map.values.first;

    map.forEach((key, value) {
      data.add(WebsiteData(key, value));
      if(value >= maxCookieCount) {
        maxCookieCount = value;
        mostCookies = key;
      } else if (value <= minCookieCount) {
        minCookieCount = value;
        leastCookies = key;
      } else {

      }
    });

    if (leastCookies == null) {
      setState(() {
        leastCookies = mostCookies;
      });
    }

    return [
      new charts.Series<WebsiteData, String>(
        id: 'Doughnut',
        domainFn: (WebsiteData ws, _) => ws.name,
        measureFn: (WebsiteData ws, _) => ws.numberOfCookies,
        data: data,
      )
    ];
  }

  /// The cookies durations vary a lot. So this function will take the current
  /// time and perform a subtraction of NOW and the cookies expirationDate.
  /// Then all cookies are grouped by  defined time frames.
  Future<List<charts.Series<dynamic, String>>> generateLineData(List<Cookie> list) async {
    int lessThanOneDay = 0;
    int lessThanOneWeek = 0;
    int lessThanOneMonth = 0;
    int lessThanOneYear = 0;
    int lessThanTenYears = 0;
    int moreThanTenYears = 0;


    list.forEach((element) {
      if(element.expirationDate != null) {
        Duration duration = Duration(milliseconds: durationFromToday(element.expirationDate.toInt() * 1000));
        if (duration.inDays < 1) {
          lessThanOneDay++;
        } else if (duration.inDays >= 1 && duration.inDays < 7) {
          lessThanOneWeek++;
        } else if (duration.inDays >= 7 && duration.inDays < 31) {
          lessThanOneMonth++;
        } else if (duration.inDays >= 31 && duration.inDays < 365) {
          lessThanOneYear++;
        } else if (duration.inDays >= 365 && duration.inDays < 3650) {
          lessThanTenYears++;
        } else if (duration.inDays >= 3650) {
          moreThanTenYears++;
        }
      } else {
        lessThanOneDay++; //These are session cookies that do NOT have duration.
      }
    });

    final data = [
      CookieData("< 1 Day", lessThanOneDay),
      CookieData("< 1 Week", lessThanOneWeek),
      CookieData("< 1 Month", lessThanOneMonth),
      CookieData("< 1 Year", lessThanOneYear),
      CookieData("< 10 Years", lessThanTenYears),
      CookieData("10+ Years", moreThanTenYears),
    ];

    return [
      new charts.Series<CookieData, String>(
        id: 'Duration',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (CookieData cookies, _) => cookies.duration,
        measureFn: (CookieData cookies, _) => cookies.amount,
        data: data,
      )
    ];
  }

  void showDeleteDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text('Withdraw consent'),
            content: Text('Would you like to permanently erase all of your stored data?'),
            actions: <Widget> [
              MaterialButton(
                child: Text('No, keep consent'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                    side: BorderSide(color: Colors.grey)
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              MaterialButton(
                child: Text('Yes, withdraw consent'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                    side: BorderSide(color: Colors.grey)
                ),
                onPressed: () {
                  webDataProvider.deleteCookies(widget.userId);
                  Navigator.pop(context);
                  showDeleteSuccessDialog();
                },
              )
            ]
        )
    );
  }

  void showDeleteSuccessDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your data has been erased!'),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 75,
                ),
              ],
            ),
            actions: <Widget> [
              MaterialButton(
                child: Text('Okay'),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ]
        )
    );
  }

  int durationFromToday(int duration) {
    int currentTimeInMs = DateTime.now().millisecondsSinceEpoch;
    return duration - currentTimeInMs;
  }

}

/// Website data for the doughnut chart.
class WebsiteData {
  final String name;
  final int numberOfCookies;

  WebsiteData(this.name, this.numberOfCookies);
}

/// Cookie data for the line chart.
class CookieData{
  final String duration;
  final int amount;

  CookieData(this.duration, this.amount);
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}