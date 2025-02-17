import 'dart:typed_data';
import 'package:chefbot/api/gemini_services_recipe_generate.dart';
import 'package:chefbot/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class RecipeGenerateView extends StatefulWidget {
  final bool isIngredient;
  const RecipeGenerateView({super.key, required this.isIngredient});

  @override
  State<RecipeGenerateView> createState() => _RecipeGenerateViewState();
}

class _RecipeGenerateViewState extends State<RecipeGenerateView> {
  final _ingredientController = TextEditingController();
  final _numberOfPeopleController = TextEditingController();
  final _dietController = TextEditingController();
  String recipeResult = "";
  bool isLoading = false;
  final gemini = Gemini.instance;
  ScrollController markDownController = ScrollController();
  Uint8List? selectedImage;
  final ImagePicker picker = ImagePicker();
  bool isImageOn = false;

  void pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImage = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isIngredient
                      ? "Buat resep dari bahan makananmu"
                      : "Food to Recipe",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (recipeResult.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: recipeResult));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resep disalin ke clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
            child: Column(
              children: [
                Visibility(
                  visible: widget.isIngredient,
                  child: Row(
                    children: [
                      Text(
                        widget.isIngredient
                            ? "Upload gambar bahan makanan"
                            : "Upload image of food",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isImageOn,
                        onChanged: (value) {
                          setState(() {
                            isImageOn = value;
                          });
                        },
                        activeColor: Colors.blueGrey,
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: !isImageOn && widget.isIngredient,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _ingredientController,
                        keyboardType: TextInputType.multiline,
                        text: "Bahan makanan apa yang kamu punya?",
                        hintText: "Ayam, Nasi, Garam, dll.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          CustomTextField(
                            controller: _numberOfPeopleController,
                            keyboardType: TextInputType.number,
                            text: "Jumlah orang",
                            hintText: "1, 2, 3, dst.",
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _dietController,
                            keyboardType: TextInputType.multiline,
                            text: "Diet",
                            hintText: "Vegan, Vegetarian, etc.",
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _numberOfPeopleController,
                              keyboardType: TextInputType.number,
                              text: "Jumlah orang",
                              hintText: "1, 2, 3, dst.",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _dietController,
                              keyboardType: TextInputType.multiline,
                              text: "Diet",
                              hintText: "Vegan, Vegetarian, etc.",
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                Visibility(
                  visible: isImageOn || !widget.isIngredient,
                  child: Column(
                    children: [
                      Text(
                        widget.isIngredient
                            ? "Upload gambar bahan makanan"
                            : "Upload image of food",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blueGrey,
                              width: 2,
                            ),
                          ),
                          child: selectedImage == null
                              ? const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.blueGrey,
                                    size: 100,
                                  ),
                                )
                              : Image.memory(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    if (selectedImage == null &&
                        _ingredientController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            "Tolong input bahan makanan atau upload gambar bahan makanan",
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    widget.isIngredient
                        ? GeminiServices(gemini: gemini)
                            .masterAgentForIngredientsToRecipe(
                            isImageOn ? "" : _ingredientController.text,
                            _numberOfPeopleController.text,
                            _dietController.text,
                            isImageOn ? selectedImage : null,
                          )
                            .then((result) {
                            setState(() {
                              recipeResult = result;
                              isLoading = false;
                            });
                          })
                        : GeminiServices(gemini: gemini)
                            .masterAgentForFoodToRecipe(
                            _numberOfPeopleController.text,
                            _dietController.text,
                            selectedImage,
                          )
                            .then((result) {
                            setState(() {
                              recipeResult = result;
                              isLoading = false;
                            });
                          });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Dapatkan Resep 🍳",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Visibility(
                  visible: isLoading,
                  child: LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Align(
                        alignment: Alignment.center,
                        child: Lottie.asset(
                          'assets/backgrounds/response_anim.json',
                          width: 280,
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
                ),
                Visibility(
                  visible: recipeResult.isNotEmpty,
                  child: Column(
                    children: [
                      const Text(
                        "Horee, ini resep buatmu!",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blueGrey,
                            width: 2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: markDownController,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Markdown(
                              shrinkWrap: true,
                              controller: markDownController,
                              styleSheet: MarkdownStyleSheet(
                                // listIndent:
                                a: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.normal,
                                ),
                                p: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                                code: const TextStyle(
                                  color: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  fontSize: 12,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  // glassy effect for gradient
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromRGBO(41, 41, 41, 0.4),
                                      Color.fromRGBO(59, 59, 59, 0.2),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  // backgroundBlendMode: BlendMode.lighten,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.2),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  // color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                h1: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                h4: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                h5: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                h6: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                em: const TextStyle(
                                  color: Colors.black,
                                ),
                                strong: const TextStyle(
                                  color: Colors.black,
                                ),
                                del: const TextStyle(
                                  color: Colors.black,
                                ),
                                blockquote: const TextStyle(
                                  color: Colors.black,
                                ),
                                img: const TextStyle(
                                  color: Colors.black,
                                ),
                                checkbox: const TextStyle(
                                  color: Colors.black,
                                ),
                                listBullet: const TextStyle(
                                  color: Colors.black,
                                ),
                                tableHead: const TextStyle(
                                  color: Colors.black,
                                ),
                                tableBody: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              physics: const NeverScrollableScrollPhysics(),
                              data: recipeResult,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
