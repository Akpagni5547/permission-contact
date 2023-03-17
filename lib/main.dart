import 'package:contact_list/page_one.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

import 'design_contact.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PageOne(),
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
  int _counter = 0;
  List<Contact> contactsList = [];

  // void _incrementCounter() {
  //   setState(() {
  //     _counter++;
  //   });
  // }

  Future<List<Contact>> getPhoneContacts() async {
    Iterable<Contact> contacts = await ContactsService.getContacts();
    return contacts.toList();
  }

  void _incrementCounter() async {
    var status = await Permission.contacts.status;
    if(status.isGranted) {
      List<Contact> contact = await getPhoneContacts();
      setState(() {
        contactsList = contact;
      });
    } else {
      if (await Permission.contacts.request().isGranted) {
        print('permission was granted');
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
        Container(
          height: 500,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: contactsList.length,
            itemBuilder: (BuildContext context, int index) {
              final contact = contactsList[index];
              print(contact.phones![0].value);
              return ListTile(
                title: Text(contact.displayName ?? ''),
                subtitle: Text(contact.phones![0].value!),
              );
            },
          ),
        ),
            const SizedBox(
              height: 50,
            ),
            const Text('hello')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
