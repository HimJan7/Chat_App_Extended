import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class DataType extends StatelessWidget {
  String? imageUrl;
  final _fireStore = FirebaseFirestore.instance;

  void selectFile(bool imgSource) async {
    XFile? file = await ImagePicker().pickImage(
        source: imgSource ? ImageSource.gallery : ImageSource.camera);
    if (file != null) {
      print('name of file' + file.name);
      uploadFile(file);
    } else {
      imageUrl = '';
    }
  }

  void uploadFile(XFile? newFile) async {
    try {
      firebase_storage.UploadTask uploadingTask;
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('product')
          .child('/' + newFile!.name);

      uploadingTask = ref.putFile(File(newFile.path));

      await uploadingTask.whenComplete(() => null);
      String uploadedUrl = await ref.getDownloadURL();
      print('image url' + uploadedUrl);
      _fireStore.collection('messages').add({
        'text': '',
        'sender': loggedInUser!.email,
        'date': DateTime.now().toIso8601String().toString(),
        'url': uploadedUrl,
      });
    } catch (e) {
      print(e);
      imageUrl = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                selectFile(true);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Gallery Image'),
                  Icon(Icons.image),
                ],
              )),
          ElevatedButton(
              onPressed: () {
                selectFile(false);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Camera Image'),
                  Icon(Icons.image),
                ],
              )),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Audio'),
                  Icon(Icons.mic),
                ],
              )),
        ],
      ),
    );
  }
}
