import 'package:flutter/material.dart';
import 'package:news_app/models/category_model.dart';
import 'package:news_app/widgets/category_card.dart';

class CategoriesListView extends StatelessWidget {
  CategoriesListView({
    super.key,
  });

  final List<CategoryModel> categories = [
    CategoryModel(
      image: 'assets/images/sports.avif',
      categoryName: 'sports',
    ),
    CategoryModel(
      image: 'assets/images/technology.jpeg',
      categoryName: 'technology',
    ),
    CategoryModel(
      image: 'assets/images/business.avif',
      categoryName: 'business',
    ),
    CategoryModel(
      image: 'assets/images/health.avif',
      categoryName: 'health',
    ),
    CategoryModel(
      image: 'assets/images/science.avif',
      categoryName: 'science',
    ),
    CategoryModel(
      image: 'assets/images/entertaiment.avif',
      categoryName: 'entertainment',
    ),
    CategoryModel(
      image: 'assets/images/general.avif',
      categoryName: 'general',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (contecxt, index) {
            return CategoryCard(
              category: categories[index],
            );
          }),
    );
  }
}
