import 'package:flutter/material.dart';

import 'package:smartstitch/core/theme/app.theme.dart';


class StatusBadge extends StatelessWidget {

  const StatusBadge({
    super.key,
    required this.status,
  });


  final String status;


  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;


    final bool published =
        status.toLowerCase() == "published";


    final Color color =
        published
            ? AppColors.success
            : AppColors.warning;


    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),


      decoration: BoxDecoration(

        color: color.withValues(
          alpha: isDark ? .20 : .12,
        ),


        borderRadius:
            AppRadius.full,


        border: Border.all(
          color: color.withValues(
            alpha: .35,
          ),
        ),

      ),


      child: Row(

        mainAxisSize:
            MainAxisSize.min,


        children: [

          Container(

            width: 6,
            height: 6,

            decoration:
                BoxDecoration(

              shape:
                  BoxShape.circle,

              color:
                  color,

            ),
          ),


          const SizedBox(width: 6),


          Text(

            published
                ? "Published"
                : "Draft",


            style:
                AppTextStyles.labelSmall
                    .copyWith(

              color:
                  color,

              fontWeight:
                  FontWeight.w600,

            ),
          ),

        ],
      ),
    );
  }
}