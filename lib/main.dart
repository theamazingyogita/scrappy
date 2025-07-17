import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrappy Web',
      theme: ThemeData(
        primaryColor: const Color(0xffD3452E),
        appBarTheme: AppBarTheme(color: const Color(0xffD3452E)),
      ),
      home: const MyHomePage(title: "Scrappy"),
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
  late TextEditingController controller;
  bool _isLoading = false;
  bool _isSuccess = false;
  List<List<String>>? _csvRows;

  @override
  void initState() {
    controller = TextEditingController();
    controller.addListener(() {
      if (controller.text.isEmpty && _isSuccess) {
        setState(() {
          _isSuccess = false;
          _csvRows = null;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _scrapeData(String url) async {
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Not a valid link")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _csvRows = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://scrappy-backend.vercel.app/api/scrape?url=$url'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];

        // Build CSV rows
        final rows = [
          ['Tag', 'Content'],
          for (var item in data)
            [item['tag'].toString(), item['content'].toString()],
        ];

        setState(() {
          _csvRows = rows;
          _isSuccess = true;
        });
      } else {
        throw Exception("Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Scraping error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.isAbsolute) &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
  void _downloadCSV() {
    if (_csvRows == null || _csvRows!.isEmpty) return;

    final csv = const ListToCsvConverter().convert(_csvRows!);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'scraped_data_${DateTime.now().millisecondsSinceEpoch}.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffD3452E),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Enter the URL to scrape the data:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w200,
                        ),
                        onEditingComplete: () {
                          setState(() {
                            _isSuccess = false;
                          });
                          print("filed submitted::");
                        },
                        onFieldSubmitted: (value) {
                          print("filed submitted::");
                        },

                        decoration: const InputDecoration(
                          hintText: "Enter URL",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        fixedSize: WidgetStateProperty.all(
                          const Size.fromHeight(60),
                        ),
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : _isSuccess
                          ? () {
                              setState(() {
                                controller.clear();
                                _isSuccess = false;
                                _isLoading = false;
                              });
                            }
                          : () => _scrapeData(controller.text.trim()),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            )
                          : Text(
                              _isSuccess ? "Clear" : "Start Scraping",
                              style: TextStyle(
                                color: Color(0xffD3452E),
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isSuccess)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '✅ Data scraped successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Download Data',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed: _downloadCSV,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
