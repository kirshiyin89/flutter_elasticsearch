import 'dart:html';

import 'package:flutter/material.dart';

import 'package:elastic_client/elastic_client.dart' as elastic;
import 'package:flutter_search/book.dart';

import 'http_trans_impl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Book Finder Demo'),
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
  final textController = TextEditingController();
  List<Book> resultBookList = List();
  bool searchStarted = false;

  Future indexCall(String queryString) async {
    List<String> _keywords = [
      "title",
      "authors",
      "tags",
      "series",
      "languages",
      "isbn"
    ];

    var uri = Uri.parse('http://127.0.0.1:9200/');
    final transport = OwnHttpTransport(uri);
    final client = elastic.Client(transport);

    var conditions = List();

    for (final _keyword in _keywords) {
      conditions.add(elastic.Query.match(_keyword, queryString));
    }

    var query = elastic.Query.bool(should: conditions);
    final searchResult = await client.search('books', '_doc', query, source: true);
    var booksList = List<Book>();
    for (final sr in searchResult.hits) {
      Map<dynamic, dynamic> currDoc = sr.doc;
      print(currDoc);
      booksList.add(Book(
          currDoc['title'],
          currDoc['authors'],
          currDoc['isbn'].toString(),
          currDoc['languages'],
          currDoc['tags'],
          currDoc['series']));
    }

    setState(() {
      resultBookList.clear();
      resultBookList.addAll(booksList);
      searchStarted = true;
    });
    await transport.close();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              width: 300.0,
              child: TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 5.0),
                    ),
                    hintText: 'Enter a search term'),
                textAlign: TextAlign.center,
                // detects Enter key
                onSubmitted: (value) {
                  indexCall(value);
                },
                textInputAction: TextInputAction.search,
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  await indexCall(textController.text);
                },
                child: Icon(Icons.search)),
            _createDataTable(this.resultBookList),
          ],
        ),
      ),
    );
  }

  _createDataTable(List<Book> resultBookList) {
    if (resultBookList.isEmpty) {
      if (searchStarted) {
        return Text("No books found");
      } else {
        return Container();
      }
    }
    return DataTable(columns: const <DataColumn>[
      DataColumn(
        label: Text(
          'Title',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Author',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Tag',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Language',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'IBSN',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Series',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      )
    ], rows: _createDataRows(this.resultBookList));
  }
}

_createDataRows(List<Book> resultBookList) {
  return resultBookList.map((e) => _mapBook(e)).toList();
}

DataRow _mapBook(Book b) {
  return DataRow(cells: <DataCell>[
    DataCell(Text(b.title)),
    DataCell(Text(b.author)),
    DataCell(Text(b.tag)),
    DataCell(Text(b.language)),
    DataCell(Text(b.isbn)),
    DataCell(Text(b.series))
  ]);
}
