import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

List<File?> images = [];
List<String> descriptions = [];
String? currentDesc;
String? claimnr;
String? vehicle;
bool gotClaim = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final picker = ImagePicker();
  final pdf = pw.Document();

  // File? _image;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF maker'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              getClaimnr();
            },
            style: TextButton.styleFrom(primary: Colors.black),
            icon: Icon(Icons.account_circle_outlined),
            label: Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        child: Icon(Icons.add),
      ),
      body: Photos(),
    );
  }

  Future getClaimnr() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(
                  'Enter vehicle information',
                  style: TextStyle(fontSize: 14),
                ),
                content: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        claimnr = value;
                      },
                      decoration: InputDecoration(hintText: 'Claim nr.'),
                    ),
                    TextField(
                      onChanged: (value) {
                        vehicle = value;
                      },
                      decoration:
                          InputDecoration(hintText: 'Vehicle make/model'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        createPDF();
                        savePDF();
                      },
                      child: Text('SUBMIT'))
                ]));
  }

  Future savePDF() async {
    try {
      // final dir = await getExternalStorageDirectory();
      // final file = File('${dir?.path}${claimnr}.pdf');

      final dir = (await getExternalStorageDirectories(
              type: StorageDirectory.downloads))!
          .first;
      final file = File('${dir.path}/${claimnr}.pdf');

      await file.writeAsBytes(await pdf.save());
      print(dir.path);
      print('saved');
      print(pdf);
      final Email email = Email(
        body: '${vehicle}',
        subject: '$claimnr',
        // recipients: ['darrat199@gmail.com'],
        attachmentPaths: ['${dir.path}/${claimnr}.pdf'],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
    } catch (e) {
      print('error saving');
    }
  }

  Future createPDF() async {
    List<pw.MemoryImage> memoryImages = [];
    for (var i = 0; i < images.length; i++) {
      setState(() {
        memoryImages.add(pw.MemoryImage(images[i]!.readAsBytesSync()));
      });
    }
    for (var i = 0; i < memoryImages.length; i++) {
      pdf.addPage(
        pw.Page(
            build: (pw.Context context) => pw.Center(
                    child: pw.Column(children: [
                  i == 0
                      ? pw.Text('Claim nr: ${claimnr!}',
                          style: pw.TextStyle(fontSize: 16.0))
                      : pw.Text(''),
                  i == 0
                      ? pw.Text('Vehicle: ${vehicle!}',
                          style: pw.TextStyle(fontSize: 16.0))
                      : pw.Text(''),
                  pw.Text(descriptions[i], style: pw.TextStyle(fontSize: 16.0)),
                  pw.Image(memoryImages[i])
                ]))),
      );
    }
  }

  // Future createPDF() async {
  //   List<pw.MemoryImage> memoryImages = [];
  //   for (var i = 0; i < images.length; i++) {
  //     setState(() {
  //       memoryImages.add(pw.MemoryImage(images[i]!.readAsBytesSync()));
  //     });
  //   }
  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) => pw.ListView.builder(
  //         itemCount: memoryImages.length,
  //         itemBuilder: (context, index) {
  //           return pw.Padding(
  //               padding: pw.EdgeInsets.only(top: 8.0),
  //               child: pw.Column(children: [
  //                 pw.Text(descriptions[index]),
  //                 pw.Image(memoryImages[index])
  //               ]));
  //         },
  //       ),
  //     ),
  //   );
  // }

  Future _getImage() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(
                  'Enter Description',
                  style: TextStyle(fontSize: 14),
                ),
                content: TextField(
                  onChanged: (value) {
                    currentDesc = value;
                  },
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('SUBMIT'))
                ]));
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null && currentDesc != null) {
        images.add(File(pickedFile.path));
        descriptions.add(currentDesc!);
      }
    });
  }
}

class Photos extends StatefulWidget {
  const Photos({super.key});

  @override
  State<Photos> createState() => _PhotosState();
}

class _PhotosState extends State<Photos> {
  @override
  Widget build(BuildContext context) {
    if (images != null) {
      return ListView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Column(
              children: [Text(descriptions[index]), Image.file(images[index]!)],
            ),
            // child: Image.file(images[index]!),
          );
        },
      );
    } else {
      return Container();
    }
  }
}
