import 'package:contact_list/page_tow.dart';
import 'package:flutter/material.dart';

import 'design_contact.dart';

class PageOne extends StatefulWidget {
  const PageOne({Key? key}) : super(key: key);

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
          title: const Text('Page one')
      ),
      body: Center(
          child: ElevatedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PageTwo()));
              },
              child: Text('page Two')
          )
      ),
    );
  }
}
