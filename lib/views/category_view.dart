import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:news_app/widgets/news_list_view.dart';

class CaregoryView extends StatelessWidget {
  const CaregoryView({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          category[0].toUpperCase() + category.substring(1),
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontFamily: GoogleFonts.aladin().fontFamily,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CustomScrollView(
            slivers: [
              NewsListView(category: category),
            ],
          ),
        ),
      ),
    );
  }
}
