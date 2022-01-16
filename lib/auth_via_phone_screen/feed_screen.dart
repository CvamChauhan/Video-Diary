import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:geocode/geocode.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_blackcoffer/auth_via_phone_screen/firebase_api.dart';
import 'package:video_blackcoffer/auth_via_phone_screen/login_via_phone.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<void> _pullRefresh() async {
    return Future.delayed(Duration(), () {
      setState(() {
        result = [];
        getData();
      });
    });
  }

  Future<String?> _getLocation() async {
    Location location = Location();
    PermissionStatus permission = PermissionStatus.denied;
    while (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission != PermissionStatus.granted) {
      return null;
    }
    final LocationData data = await location.getLocation();
    try {
      Address add = await GeoCode().reverseGeocoding(
          latitude: data.latitude!.toDouble(),
          longitude: data.longitude!.toDouble());
      return add.city;
    } catch (e) {
      Exception(e);
    }
  }

  void _getVideo(context) async {
    String? cityName = await _getLocation();
    XFile? record = await ImagePicker().pickVideo(
        source: ImageSource.camera, maxDuration: const Duration(seconds: 10));
    if (record == null) {
      return;
    }
    String _path = record.path;
    File video = File(_path);

    await _uploadVideo(context, cityName, _path, video);
  }

  Future<void> _uploadVideo(
      context, String? cityName, String _path, File video) async {
    TextEditingController _descriptionController = TextEditingController();
    TextEditingController _titleController = TextEditingController();
    showDialog(
        context: (context),
        builder: (context) {
          return AlertDialog(
            title: const Text("Add Details"),
            content: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: "Description"),
                  onTap: () async {
                    int i = 0;
                    while (cityName == null && i < 5) {
                      cityName = await _getLocation();
                      i++;
                    }
                  },
                ),
                TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "Title"))
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () async {
                    final ref = FirebaseStorage.instance
                        .ref('files/${basename(_path)}/');
                    ref.putFile(
                        video,
                        SettableMetadata(customMetadata: {
                          'title': _titleController.text,
                          'location': cityName ?? 'Unknown',
                          'description': _descriptionController.text,
                        }));
                    Navigator.pop(context);
                  },
                  child: const Text("Post"))
            ],
          );
        });
  }

  Future<void> _delete(String ref) async {
    await FirebaseStorage.instance.ref(ref).delete();
    setState(() {});
  }

  List<Map<String, dynamic>> list = [];
  List<Map<String, dynamic>> result = [];
  getData() async {
    final res = await FirebaseApi.loadData('files/');
    setState(() {
      result = res;
      list = result;
    });
  }

  TextEditingController _searchController = TextEditingController();
  textListner() {
    List<Map<String, dynamic>> showResult = [];
    if (_searchController.text != '') {
      for (var items in list) {
        if (items['title']
            .toString()
            .toLowerCase()
            .contains(_searchController.text.toLowerCase())) {
          showResult.add(items);
        }
      }
    } else {
      showResult = List.from(list);
    }
    result = showResult;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    _searchController.addListener(textListner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          _getVideo(context);
        },
        child: const Icon(
          Icons.video_call,
        ),
      ),
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: TextField(
                    cursorColor: Colors.black,
                    controller: _searchController,
                    decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                        focusColor: Colors.black,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Colors.white)),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogInViaPhone()));
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ))
              ],
            ),
            result.isEmpty
                ? CircularProgressIndicator()
                : buildListView(result),
          ],
        ),
      ),
    );
  }

  Expanded buildListView(List<Map<String, dynamic>> files) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> file = files[index];

            final VideoPlayerController fileController =
                VideoPlayerController.network(file['url'])
                  ..addListener(() {})
                  ..setLooping(true)
                  ..initialize();
            return Column(
              children: [
                const Divider(
                  color: Colors.grey,
                  thickness: 1.2,
                ),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      file['title'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Expanded(
                      child: SizedBox(
                        width: double.infinity,
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(file['location'],
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(
                      width: 5,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                GestureDetector(
                  onLongPress: () {
                    showDialog(
                        context: (context),
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Do you want to delete?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _delete(file['path']);
                                  Navigator.pop(context);
                                },
                                child: const Text("Yes"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: const Text("No"),
                              )
                            ],
                          );
                        });
                  },
                  onTap: () {
                    fileController.value.isPlaying
                        ? fileController.pause()
                        : fileController.play();
                  },
                  child: AspectRatio(
                      aspectRatio: fileController.value.aspectRatio,
                      child: VideoPlayer(fileController)),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.thumb_up,
                      color: Colors.red,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.comment,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      file['description'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
