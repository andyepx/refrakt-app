import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refrakt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(1, 178, 222, 62)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Refrakt'),
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
  late Future<Map<String, dynamic>> _data;
  var _currentActiveTab = 0;
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _data = getData();
  }

  Future<Map<String, dynamic>> getData() async {
    const urls = [
      'https://refrakt.app/api/trpc/edge/feeds.genericFeed?input=%7B%22json%22%3A%7B%22filters%22%3A%7B%22onlyFollowing%22%3Afalse%7D%2C%22cursor%22%3Anull%7D%2C%22meta%22%3A%7B%22values%22%3A%7B%22cursor%22%3A%5B%22undefined%22%5D%7D%7D%7D',
      'https://refrakt.app/api/trpc/edge/feeds.genericFeed?input=%7B%22json%22%3A%7B%22filters%22%3A%7B%22published%22%3Afalse%2C%22curated%22%3Atrue%7D%2C%22cursor%22%3Anull%7D%2C%22meta%22%3A%7B%22values%22%3A%7B%22cursor%22%3A%5B%22undefined%22%5D%7D%7D%7D',
    ];

    final response = await http.get(Uri.parse(urls[_currentActiveTab]));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load');
    }
  }

  Future<Map<String, dynamic>> login(String email) async {
    final response = await http.post(
        Uri.parse(
            "https://refrakt.app/api/trpc/edge/auth.requestChallenge?batch=1"),
        body: jsonEncode({
          "0": {
            "json": {"email": "$email"}
          }
        }));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
            InkWell(
              child: CircleAvatar(
                foregroundImage: _userId != ''
                    ? NetworkImage(
                        'https://images.refrakt.app/v2/variant/${_userId}/thumbnail')
                    : null,
              ),
              onTap: () {
                if (_userId == '') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Enter your Refrakt email"),
                      content: TextField(
                        onSubmitted: (value) {
                          login(value).then((value) {
                            print(value);

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Insert auth code..."),
                                content: TextField(onSubmitted: (value) {
                                  login(value).then((value) {
                                    print(value);
                                    setState(() {
                                      _userId = value['result']['data']['json']
                                          ['userId'];
                                    });
                                  });
                                }),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<Map<dynamic, dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                children: (snapshot.data!['result']['data']['json']['items']
                        as List<dynamic>)
                    .map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Image(
                              image: NetworkImage(
                                "https://images.refrakt.app/v2/variant/${x['imageId']}/grid",
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  x['user']['name'] != ''
                                      ? Opacity(
                                          child: Text(x['user']['name']),
                                          opacity: .6,
                                        )
                                      : Container(),
                                  x['title'] != ''
                                      ? Text(" " + x['title'])
                                      : Container(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
              // return Text(snapshot.data!['result']['data']['json']['items'][0]['publicId']);
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Discovery',
          ),
        ],
        onTap: (int index) {
          setState(() {
            _currentActiveTab = index;
            _data = getData();
          });
        },
        currentIndex: _currentActiveTab,
      ),
    );
  }
}
