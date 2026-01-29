
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/utils.dart';

class _ProductAddImagesState extends State<ProductAddImages> {
  late List<ImageModel> _imageModels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageModels.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(m.url, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageModels.remove(m);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final picker = ImagePicker();

                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        _imageModels.add(ImageModel(url: pickedFile.path, bytes: bytes)); // In a real app, upload and get URL
                      });
                    }
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Error picking image: $e')));
                  }
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _imageModels = widget.imageModels;
  }
}

class ProductAddImages extends StatefulWidget {
  final List<ImageModel> imageModels;

  const ProductAddImages({super.key, required this.imageModels});

  @override
  State<ProductAddImages> createState() => _ProductAddImagesState();
}
