import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  String? _csvPath;

  Future<void> _scrapeAndExport(String path) async {
    setState(() {
      _isLoading = true;
      _csvPath = null;
    });

    try {
      final String baseurl = "http://localhost:3008/scrape?";
      final response = await http.get(Uri.parse("${baseurl}url=${path}"));
      if (response.statusCode == 200) {
        print("got response::${response.body}");
        final document = html_parser.parse(response.body);
        print("got document::${document}");
      } else {
        throw Exception("Failed with status code ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Scaffold(
      backgroundColor: Color(0xffD3452E),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Enter the URL to scrap the data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w200,
                          ),
                          textAlign: TextAlign.start,
                          decoration: InputDecoration(
                            hintText: "Enter URL",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            hintMaxLines: 1,
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              leadingDistribution:
                                  TextLeadingDistribution.proportional,
                            ),
                            alignLabelWithHint: false,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          fixedSize: WidgetStatePropertyAll(
                            Size.fromHeight(60),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _scrapeAndExport(controller.text.trim()),
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text(
                                "Start Scrapping",
                                style: TextStyle(
                                  color: Color(0xffD3452E),
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
