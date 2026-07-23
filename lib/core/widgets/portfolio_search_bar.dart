import 'package:flutter/material.dart';

import 'package:smartstitch/core/theme/app.theme.dart';

class PortfolioSearch extends StatelessWidget {

  const PortfolioSearch({
    super.key,
    required this.controller,
    required this.onChanged,
  });


  final TextEditingController controller;
  final ValueChanged<String> onChanged;


  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness == Brightness.dark;


    return TextField(

      controller: controller,

      onChanged: onChanged,


      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),


      decoration: InputDecoration(

        hintText:
            "Search your portfolio...",


        prefixIcon: const Icon(
          Icons.search_rounded,
        ),


        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                ),

                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,


        filled: true,


        fillColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,


        border: OutlineInputBorder(

          borderRadius:
              AppRadius.medium,

          borderSide: BorderSide.none,

        ),


        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              AppRadius.medium,

          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),

        ),


        focusedBorder:
            OutlineInputBorder(

          borderRadius:
              AppRadius.medium,

          borderSide:
              const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),

        ),

      ),
    );
  }
}