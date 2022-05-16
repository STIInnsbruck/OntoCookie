import 'dart:io';
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cookie_consent_vis/screens/overview_page.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cookie Consent Visualiser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Cookie Consent Visualiser'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String STEP_1_TEXT =
      "Step 1. Install the Cookie-Editor extension.";
  final String STEP_3_TEXT =
      "Step 3. For each website, after browsing, click on the cookie icon to export the cookies\ninto your clipboard.";
  final String STEP_2_TEXT =
      "Step 2. If not already done, please generate an ID by clicking the button below.\nThen enter your generated ID in the text box.\nThis only binds your cookies to the entered ID and does NOT have any other relation to you.";
  final String STEP_5_TEXT =
      "Step 4. Click on ADD COOKIES and paste in the exported cookies from one website,\nthen confirm your addition. You will need to do this for each website separately.";

  TextEditingController idController = new TextEditingController();
  TextEditingController textController = new TextEditingController();
  List<String> cookieStrings = [];
  String cookies = "";

  FocusNode _idFocusNode = FocusNode();
  FocusNode _cookieFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();

  FilePickerResult result;
  File file;
  bool visualising = false;
  bool archiveData = false;

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  var _deviceData;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    WebBrowserInfo deviceData;
    deviceData = await deviceInfoPlugin.webBrowserInfo;
    setState(() {
      _deviceData = deviceData.browserName;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Running on: ${_deviceData.toString()}");

    return Scaffold(
        body: visualising
            ? OverviewPage(cookies, idController.text, archiveData)
            : Center(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          stepText(STEP_1_TEXT),
                          Container(width: 10),
                          extensionButton()
                        ],
                      ),
                      SizedBox(height: 20),
                      stepText(STEP_2_TEXT),
                      generateIdLink(),
                      SizedBox(height: 10),
                      idTextField(),
                      SizedBox(height: 10),
                      stepText(STEP_3_TEXT),
                      SizedBox(height: 20),
                      stepText(STEP_5_TEXT),
                      SizedBox(height: 20),
                      addCookiesButton(),
                      SizedBox(height: 20),
                      cookieBoxWithTiles(),
                      SizedBox(height: 20),
                      visualizeButton(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ));
  }

  Expanded cookieBox() {
    return Expanded(
        child: Container(
          color: Colors.grey[200],
          child: SizedBox(
              width: 1000,
              child: Scrollbar(
                  child: SingleChildScrollView(
                      child: Text(cookies,
                          style: TextStyle(color: Colors.black))))),
        ));
  }

  Expanded cookieBoxWithTiles() {
    return Expanded(
        child: Container(
          width: 1000,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
        itemCount: cookieStrings.length,
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          return cookieListItem(cookieStrings[index], index);
        }
    ))
        );
  }

  ListTile cookieListItem(String text, int index) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Container(
        height: 50,
        color: Colors.lightBlue,
        child: Row(
          children: [
            Expanded(
              child: MaterialButton(
                child: Text("Inserted cookies from website ${index+1}.", style: TextStyle(color: Colors.white)),
                color: Colors.lightBlue,
                disabledColor: Colors.lightBlue,
                enableFeedback: true,
              ),
            ),
            MaterialButton(
              color: Colors.white,
              child: Icon(Icons.remove_red_eye),
              onPressed: () {
                setState(() {
                  showSpecificWebsiteCookies(index);
                });
              },
            ),
            SizedBox(width: 10),
            MaterialButton(
              color: Colors.red,
              child: Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  cookieStrings.removeAt(index);
                });
              },
            ),
            SizedBox(width: 10)
          ],
        ),
      ),

    );
  }

  void removeNewLinesOld() {
    setState(() {
      //trim() did not seem to work for some odd reason.
      textController.text = textController.text.replaceAll("\n", "");
      textController.text = textController.text.replaceAll(" ", "");
      //     textController.text = textController.text.replaceAll("www.", ".");
    });
  }

  void removeNewLines() {
    setState(() {
      cookies = cookies.replaceAll("\n", "");
      cookies = cookies.replaceAll(" ", "");
    });
  }

  String mergeAllCookieStrings()  {
    String mergedStrings = "[";
    for(int i = 0; i < cookieStrings.length; i++) {
      mergedStrings += "\n";
      String removedFirstBracket = cookieStrings[i].replaceAll("[", "");
      String removedSecondBracket = "";
      if(i == cookieStrings.length - 1 ) {
        removedSecondBracket = removedFirstBracket.replaceAll("]", "");
      } else {
        removedSecondBracket = removedFirstBracket.replaceAll("]", ",");
      }
      mergedStrings += removedSecondBracket;
    }
    mergedStrings += "]";
    return mergedStrings;
  }

  void addUserIdIntoJson() {
    setState(() {
      cookies = cookies
          .replaceAll('\"domain\"', '\"userId\":\"${idController.text}\",\"domain\"');
    });
  }

  Text stepText(String text) {
    return Text(text,
        style: TextStyle(fontSize: 25, color: Colors.grey),
        textAlign: TextAlign.left);
  }

  Container idTextField() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        width: 1000,
        height: 50,
        child: TextFormField(
          autofocus: true,
          focusNode: _idFocusNode,
          onFieldSubmitted: (_) {
            fieldFocusChange(context, _idFocusNode, _cookieFocusNode);
          },
          controller: idController,
          maxLines: 1,
          decoration: InputDecoration(
              labelText: 'ID', hintText: 'Enter your generated ID in here...'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'To visualize your cookies, you must enter your id here.';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ));
  }

  MaterialButton addCookiesButton() {
    return MaterialButton(
      color: Colors.blue,
      padding: EdgeInsets.fromLTRB(15, 20, 15, 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.white),
          Text("Add Cookies",
              style: TextStyle(fontSize: 20, color: Colors.white))
        ],
      ),
      onPressed: () {
        showInsertCookiesDialog();
      },
    );
  }

  Container cookieTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      width: 1000,
      height: 500,
      child: TextFormField(
        focusNode: _cookieFocusNode,
        controller: textController,
        maxLines: null,
        decoration: InputDecoration(
            labelText: 'Cookies', hintText: 'Paste your cookies in here...'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'To visualize your cookies, you must first paste them here.';
          }
          return null;
        },
        textInputAction: TextInputAction.done,
      ),
    );
  }

  MaterialButton visualizeButton() {
    return MaterialButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('VISUALISE',
              style: TextStyle(fontSize: 20, color: Colors.white)),
          Icon(Icons.chevron_right, color: Colors.white)
        ],
      ),
      color: Colors.blue,
      padding: EdgeInsets.fromLTRB(30, 15, 30, 15),
      onPressed: () {
        if (_formKey.currentState.validate()) {
          showArchiveDataDialog();
        } else {
          showInputErrorDialog();
        }
      },
    );
  }

  void visualise() {
    cookies = mergeAllCookieStrings();

    cookies = cookies.replaceAll(".www", "");
    cookies = cookies.replaceAll("www.", "");
    cookies = cookies.replaceAll(".google.com", "google.com");
    cookies = cookies.replaceAll(".euronews.com", "euronews.com");
    cookies = cookies.replaceAll(".bbc.com", "bbc.com");
    cookies = cookies.replaceAll("en.wikipedia.org", "wikipedia.org");
    cookies = cookies.replaceAll(".wikipedia.org", "wikipedia.org");
    removeNewLines();
    addUserIdIntoJson();
    setState(() {
      this.visualising = true;
    });
  }

  void fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  MaterialButton extensionButton() {
    return MaterialButton(
      child: Text('Get the extension',
          style: TextStyle(fontSize: 20, color: Colors.white)),
      color: Colors.blue,
      padding: EdgeInsets.fromLTRB(30, 15, 30, 15),
      onPressed: () {
        if(_deviceData != null) {
          switch(_deviceData.toString()) {
            case "BrowserName.chrome":
              js.context.callMethod('open', [
                'https://chrome.google.com/webstore/detail/cookie-editor/hlkenndednhfkekhgcdicdfddnkalmdm?hl=en'
              ]);
              break;
            case "BrowserName.edge":
              js.context.callMethod('open', [
                'https://microsoftedge.microsoft.com/addons/detail/cookieeditor/neaplmfkghagebokkhpjpoebhdledlfi'
              ]);
              break;
            case "BrowserName.firefox":
              js.context.callMethod('open', [
                'https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search'
              ]);
              break;
            default:
              js.context.callMethod('open', [
                'https://chrome.google.com/webstore/detail/cookie-editor/hlkenndednhfkekhgcdicdfddnkalmdm?hl=en'
              ]);
          }
        }
      },
    );
  }

  MaterialButton generateIdLink() {
    return MaterialButton(
      child: Text('Open ID Generator',
          style: TextStyle(fontSize: 20, color: Colors.white)),
      color: Colors.blue,
      padding: EdgeInsets.fromLTRB(30, 15, 30, 15),
      onPressed: () {
        js.context.callMethod('open', [
          'https://passwordsgenerator.net/sha1-hash-generator/'
        ]);
      },
    );
  }

  void showInputErrorDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                title: Text('Error!'),
                content: Text(
                    'You made a mistake when entering your id or cookies.'),
                actions: <Widget>[
                  MaterialButton(
                    child: Text('Got it!'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ]));
  }

  void showSpecificWebsiteCookies(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text('Cookies for Website ${index+1}'),
            content: Container(
              width: 1000,
              height: 500,
              child: SingleChildScrollView(
                child: Text(cookieStrings[index]),
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text('Got it!'),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ]));
  }

  void showInsertCookiesDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
                title: Text('Paste in your cookies'),
                content: cookieTextField(),
                actions: <Widget>[
                  MaterialButton(
                      child:
                          Text("Cancel", style: TextStyle(color: Colors.white)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: BorderSide(color: Colors.red)),
                      color: Colors.red,
                      onPressed: () {
                        setState(() {
                          textController.text = "";
                        });
                        Navigator.pop(context);
                      }),
                  MaterialButton(
                      child: Text("Add cookies",
                          style: TextStyle(color: Colors.white)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: BorderSide(color: Colors.blue)),
                      color: Colors.blue,
                      onPressed: () {
                        if(_isValidJson(textController.text) == true) {
                          setState(() {
                            cookieStrings.add(textController.text);
                            textController.text = "";
                            Navigator.pop(context);
                          });
                        } else {
                          textController.text = "";
                          Navigator.pop(context);
                          showInvalidJsonDialog();
                        }
                      }),
                ]));
  }

  void showInvalidJsonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Oops!"),
        content: Text("It seems that your imported cookies have an invalid format.\nPlease make sure you are using the cookie extension correctly, and pasting in the correct information."),
        actions: [
          MaterialButton(
              child: Text("Okay"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: BorderSide(color: Colors.grey)),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      )
    );
  }

  void showArchiveDataDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                title: Text('Consent to store data'),
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Type of data:"),
                        Text("Purpose:"),
                        Text("Storage Location:"),
                        Text("Duration:"),
                        Text("Access:"),
                        Text("NOTE:"),
                        Text("ID:"),
                      ],
                    ),
                    SizedBox(width: 5),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Cookie data imported from the Cookie-Editor browser extension"),
                        Text("Cookie analysis and visualisation"),
                        Text("A knowledge graph in GraphDB"),
                        Text("10 Days"),
                        Text("Only authorised personnel at STI Innsbruck"),
                        Text(
                            "Consent can be revoked at any time. Please note your ID to view previously inserted cookies."),
                        Text(idController.text),
                      ],
                    )
                  ],
                ),
                actions: <Widget>[
                  MaterialButton(
                      child: Text("No, I disagree"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: BorderSide(color: Colors.grey)),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          this.archiveData = false;
                        });
                        visualise();
                      }),
                  MaterialButton(
                      child: Text("Yes, I agree"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: BorderSide(color: Colors.grey)),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          this.archiveData = true;
                        });
                        visualise();
                      })
                ]));
  }

  bool _isValidJson(String jsonString) {
    try {
      var decodedJSON = json.decode(jsonString);
    } on FormatException catch (e) {
      print('Not a valid JSON.');
      return false;
    }
    print('Valid JSON.');
    return true;
  }
}
