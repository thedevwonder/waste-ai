import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

void main() async {
  await dotenv.load(fileName: 'env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Zero Waste',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const WasteManagementTips());
  }
}

class WasteManagementTips extends StatefulWidget {
  const WasteManagementTips({super.key});

  @override
  State<WasteManagementTips> createState() => _WasteManagementTipsState();
}

class _WasteManagementTipsState extends State<WasteManagementTips> {
  File? _image;
  String? _tips;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        //image not uploaded
      }
    });
  }

  Future<void> _generateWasteManagementTips() async {
    if (_image == null) {
      return;
    }
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model =
        GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    const prompt =
        'Given an image of waste, tell me how to segregate this into wet and dry waste dustbins';
    final imageBytes = await _image!.readAsBytes();
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/png', imageBytes),
      ])
    ];
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await model.generateContent(content);
      setState(() {
        _isLoading = false;
      });
      setState(() {
        if (response.text != null) {
          _tips = response.text;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _tips = "Service not reachable. Try again!";
      });
    }
  }

  void _returnToHome() {
    setState(() {
      _image = null;
      _tips = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Center(child: Text('Waste Management AI')),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: InkWell(
                          splashColor: Colors.blue.withAlpha(30),
                          child: const SizedBox(
                              width: 300,
                              height: 100,
                              child: Center(
                                  child: Text(
                                      'Pick an image and know the difference. Help the neighbourhood by segregating waste. Save the planet, one waste at a time!'))),
                        )),
                  ),
                ),
                _image != null
                    ? Image.file(_image!)
                    : ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Pick Image'),
                      ),
                _tips != null
                    ? Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Card(
                              clipBehavior: Clip.hardEdge,
                              child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: InkWell(
                                    splashColor: Colors.blue.withAlpha(30),
                                    child: SizedBox(
                                        width: 300,
                                        height: 100,
                                        child: Center(child: Text(_tips!))),
                                  )),
                            ),
                          ),
                          ElevatedButton(
                              onPressed: _returnToHome,
                              child: const Text('Go Back'))
                        ],
                      ))
                    : (_isLoading == true)
                        ? Center(
                            child: LoadingAnimationWidget.waveDots(
                              color: Colors.black,
                              size: 50,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _generateWasteManagementTips,
                            child: const Text('Generate Tips'),
                          ),
              ],
            ),
          ),
        ));
  }
}
