import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _loading = true;
  File? _image;
  List<dynamic>? _output;
  List<String>? _labels;
  Interpreter? _interpreter;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel();
    loadLabels();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> loadLabels() async {
    try {
      final labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      _labels = labelsData.split('\n');
    } catch (e) {
      print("Error loading labels: $e");
    }
  }

 Future<void> classifyImage(File image) async {
  if (_labels == null || _labels!.isEmpty || _interpreter == null) {
    setState(() {
      _output = ['Model or labels not ready'];
      _loading = false;
    });
    return;
  }

  // Preprocess the image
  final rawImage = img.decodeImage(image.readAsBytesSync())!;
  final resizedImage = img.copyResize(rawImage, width: 224, height: 224);

  // Convert to RGB and normalize
 var input = List.generate(
  1,
  (_) => List.generate(
    224,
    (_) => List.generate(
      224,
      (_) => List.filled(3, 0.0),
    ),
  ),
);
  for (int y = 0; y < 224; y++) {
  for (int x = 0; x < 224; x++) {
    final pixel = resizedImage.getPixel(x, y);
input[0][y][x][0] = pixel.r / 255.0;
    input[0][y][x][1] = pixel.g / 255.0;
    input[0][y][x][2] = pixel.b / 255.0;
  }
}

  // Prepare output tensor
  var output = List.generate(1, (_) => List.filled(2, 0.0));
  try {
    print("Running inference...");
    _interpreter!.run(input, output);
    print("Inference successful: $output");

    setState(() {
      final probabilities = output[0];
      final maxIndex = probabilities.indexWhere((value) => value == probabilities.reduce((a, b) => a > b ? a : b));
      _output = ['${_labels![maxIndex]}'];
      _loading = false;
    });
  } catch (e) {
    print("Error during inference: $e");
    setState(() {
      _output = ['Error during inference'];
      _loading = false;
    });
  }
}

  Future<void> pickImage() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
      _loading = true;
    });
    classifyImage(_image!);
  }

  Future<void> pickGalleryImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
      _loading = true;
    });
    classifyImage(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detect Cats or Dogs"),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.amber,
      ),
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child: _loading
                    ? Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                              ),
                              Positioned(
                                right: -10,
                                top: 9,
                                child: Lottie.asset("assets/loadCat.json"),
                              ),
                              Positioned(
                                top: 5,
                                left: -50,
                                child: SizedBox(
                                  height: 200,
                                  child: Lottie.asset("assets/dog.json"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                        ],
                      )
                    : Column(
                        children: [
                          if (_image != null)
                            Container(
                              height: 250,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Opacity(
                                  opacity: .9,
                                  child: Image.file(_image!,fit: BoxFit.cover,
                                  
                                  ),
                                )
                                ),
                            ),
                          const SizedBox(height: 20),
                          if (_output != null && _output!.isNotEmpty)
                            Stack(
                              children: [
                                Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)
                                ,
                                color: Colors.amber.withOpacity(0.2)
                              ),
                            ),
                              Positioned(
                                left: MediaQuery.of(context).size.width/2-60,
                                child: Text(
                                 _output![0].toString().toUpperCase(),
                                style: const TextStyle(fontSize: 25,fontWeight: FontWeight.bold),
                                                          ),
                              ),
                              _output![0].toString().toUpperCase()=="DOG"?Positioned(
                                child: Lottie.asset("assets/dog.json")
                                ):Positioned(
          
                                child: Lottie.asset("assets/loadCat.json")
                                )
                              ],
                            )
                        ],
                      ),
              ),
              SizedBox(height: 20,),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 280,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: pickGalleryImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Pick from Gallery"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 280,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Take a Photo"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}