import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class Plant {
  final String id;
  final String name;
  final int wateringFrequency; // in days
  final String? fertilizationTimeline;
  final DateTime lastWateredDate;
  final String? imagePath;

  Plant({
    required this.id,
    required this.name,
    required this.wateringFrequency,
    this.fertilizationTimeline,
    required this.lastWateredDate,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'wateringFrequency': wateringFrequency,
      'fertilizationTimeline': fertilizationTimeline,
      'lastWateredDate': lastWateredDate.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      wateringFrequency: map['wateringFrequency'],
      fertilizationTimeline: map['fertilizationTimeline'],
      lastWateredDate: DateTime.parse(map['lastWateredDate']),
      imagePath: map['imagePath'],
    );
  }

  String get nextWateringDate {
    final nextDate = lastWateredDate.add(Duration(days: wateringFrequency));
    return DateFormat('MMM dd, yyyy').format(nextDate);
  }

  bool get needsWatering {
    final nextWatering = lastWateredDate.add(Duration(days: wateringFrequency));
    return DateTime.now().isAfter(nextWatering);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Plant> plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantStrings = prefs.getStringList('plants') ?? [];
    setState(() {
      plants = plantStrings
          .map((str) => Plant.fromMap(json.decode(str)))
          .toList();
    });
  }

  Future<void> _savePlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantStrings =
        plants.map((plant) => json.encode(plant.toMap())).toList();
    await prefs.setStringList('plants', plantStrings);
  }

  void _addPlant(Plant newPlant) {
    setState(() {
      plants.add(newPlant);
    });
    _savePlants();
  }

  void _markAsWatered(Plant plant) {
    setState(() {
      final index = plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        plants[index] = Plant(
          id: plant.id,
          name: plant.name,
          wateringFrequency: plant.wateringFrequency,
          fertilizationTimeline: plant.fertilizationTimeline,
          lastWateredDate: DateTime.now(),
          imagePath: plant.imagePath,
        );
      }
    });
    _savePlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images.jpg",
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "PlantCare",
                    style: GoogleFonts.pacifico(
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: plants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 80,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No plants yet!\nAdd your first plant to get started.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 28,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildPlantGrid(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text("Add New Plant"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700]!.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    onPressed: () async {
                      final newPlant = await Navigator.push<Plant>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddPlantPage()),
                      );
                      if (newPlant != null) {
                        _addPlant(newPlant);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _buildPlantCard(plant);
      },
    );
  }

  Widget _buildPlantCard(Plant plant) {
    final daysUntilWatering = plant.lastWateredDate
        .add(Duration(days: plant.wateringFrequency))
        .difference(DateTime.now())
        .inDays;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          _showPlantDetails(plant);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: plant.imagePath != null
                  ? Image.asset(
                      plant.imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      color: Colors.green[50],
                      child: Center(
                        child: Icon(
                          Icons.eco,
                          size: 60,
                          color: Colors.green[300],
                        ),
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 16,
                        color: plant.needsWatering
                            ? Colors.red[300]
                            : Colors.lightBlue[200],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        plant.needsWatering
                            ? "Needs water!"
                            : "Water in $daysUntilWatering days",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: plant.needsWatering
                              ? Colors.red[300]
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (plant.needsWatering)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "URGENT",
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlantDetails(Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                plant.name,
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 20),
              if (plant.imagePath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      plant.imagePath!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.eco,
                      size: 80,
                      color: Colors.green[300],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildDetailRow(
                Icons.water_drop,
                "Watering",
                "Every ${plant.wateringFrequency} days\nNext: ${plant.nextWateringDate}",
                plant.needsWatering ? Colors.red[400] : Colors.blue[400],
              ),
              const SizedBox(height: 10),
              if (plant.fertilizationTimeline != null)
                _buildDetailRow(
                  Icons.eco,
                  "Fertilization",
                  plant.fertilizationTimeline!,
                  Colors.orange[400],
                ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.water_drop),
                  label: const Text("Mark as Watered"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    _markAsWatered(plant);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${plant.name} marked as watered!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      IconData icon, String title, String value, Color? color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color?.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddPlantPage extends StatefulWidget {
  const AddPlantPage({super.key});

  @override
  State<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wateringController = TextEditingController(text: "7");
  final _fertilizationController = TextEditingController();
  String? _selectedImage;

  final List<String> plantImages = [
    'assets/plant1.jpg',
    'assets/plant2.jpg',
    'assets/plant3.jpeg',
    'assets/plant4.jpeg',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _wateringController.dispose();
    _fertilizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Plant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _savePlant,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images.jpeg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selectImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.green[300]!,
                          width: 2,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.asset(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.green[300],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Tap to add plant photo",
                                  style: GoogleFonts.lato(
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration("Plant Name", Icons.eco),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a plant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _wateringController,
                    decoration: _buildInputDecoration(
                        "Watering Frequency (days)", Icons.water_drop),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter watering frequency';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _fertilizationController,
                    decoration: _buildInputDecoration(
                        "Fertilization Timeline (optional)", Icons.agriculture),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _savePlant,
                    child: const Text("Save Plant"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  void _selectImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: plantImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = plantImages[index];
                  });
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    plantImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _savePlant() {
    if (_formKey.currentState!.validate()) {
      final newPlant = Plant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        wateringFrequency: int.parse(_wateringController.text),
        fertilizationTimeline: _fertilizationController.text.isEmpty
            ? null
            : _fertilizationController.text,
        lastWateredDate: DateTime.now(),
        imagePath: _selectedImage,
      );
      Navigator.pop(context, newPlant);
    }
  }
}