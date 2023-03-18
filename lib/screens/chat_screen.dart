import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
//import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

User? loggedInUser;
final _fireStore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const id = 'Chat_Screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final messageController = TextEditingController();
  String? textFieldData;
  String imageUrl = '';
  bool _isButtonDisabled = false;
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser!;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser!.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void selectFile(bool imgSource) async {
    setState(() {
      _isButtonDisabled = true;
    });

    var file = await ImagePicker().pickImage(
        source: imgSource ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 50);
    if (file == null) {
      return;
    }
    // file = await compressImage(file.path, 35);
    uploadFile(file);
  }

/*
  Future<dynamic> compressImage(String path, int quality) async {
    final newPath = p.join((await getTemporaryDirectory()).path,
        '${DateTime.now()}.${p.extension(path)}');
    final result = await FlutterImageCompress.compressAndGetFile(path, newPath,
        quality: quality);
    return result;
  }
*/
  void uploadFile(XFile? newFile) async {
    try {
      firebase_storage.UploadTask uploadingTask;
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('product')
          .child('/' + newFile!.name);

      print('Reference == ');
      print(ref);

      uploadingTask = ref.putFile(File(newFile.path));

      await uploadingTask.whenComplete(() => null);
      String uploadedUrl = await ref.getDownloadURL();

      imageUrl = uploadedUrl;
      print('image url == ' + imageUrl);
    } catch (e) {
      print(e);
      imageUrl = '';
    }
    setState(() {
      _isButtonDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            messageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                        onPressed: () {
                                          selectFile(true);
                                          Navigator.pop(context);
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Audio'),
                                            Icon(Icons.mic),
                                          ],
                                        )),
                                  ],
                                ),
                              ));
                    },
                    child: Container(
                        child: Row(
                      children: [
                        SizedBox(
                          width: 5,
                        ),
                        Icon(Icons.image),
                        SizedBox(
                          width: 5,
                        ),
                      ],
                    )),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        textFieldData = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_isButtonDisabled == false) {
                        messageController.clear();
                        String? newMessageText = textFieldData;

                        if (imageUrl != '' || newMessageText != '') {
                          _fireStore.collection('messages').add({
                            'text': newMessageText,
                            'sender': loggedInUser!.email,
                            'date': DateTime.now().toIso8601String().toString(),
                            'url': imageUrl,
                          });
                          textFieldData = '';
                          imageUrl = '';
                        }
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          _isButtonDisabled == false
                              ? Colors.lightBlueAccent.shade400
                              : Colors.lightBlueAccent.shade100),
                    ),
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class messageStream extends StatelessWidget {
  const messageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data!.docs.reversed;
          List<messageBubble> messageBubbles = [];

          for (var message in messages) {
            final messageText = message.get('text');
            final messagesender = message.get('sender');
            final readImageUrl = message.get('url');
            final currentuser = loggedInUser?.email;

            messageBubbles.add(
              messageBubble(
                text: messageText,
                sender: messagesender,
                self: currentuser == messagesender,
                url: readImageUrl,
              ),
            );
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: messageBubbles,
            ),
          );
        } else {
          return Text('data not found');
        }
      },
    );
  }
}

class messageBubble extends StatelessWidget {
  messageBubble({this.text, this.sender, this.self = true, required this.url});

  String? sender;
  String? text;
  bool self = true;
  String url;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            self ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$sender',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: self
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: self ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: url == ''
                  ? Text(
                      '$text',
                      style: TextStyle(
                          fontSize: 15,
                          color: self ? Colors.white : Colors.black54),
                    )
                  : text == ''
                      ? Container(
                          width: 200,
                          child: Image.network(url),
                        )
                      : Column(children: [
                          Container(
                              width: 200,
                              child: Column(
                                children: [
                                  Image.network(url),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    '$text',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: self
                                            ? Colors.white
                                            : Colors.black54),
                                  ),
                                ],
                              )),
                        ]),
            ),
          ),
        ],
      ),
    );
  }
}
