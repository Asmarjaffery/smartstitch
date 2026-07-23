import 'package:flutter/material.dart';


class EmptyState extends StatelessWidget {


  const EmptyState({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return Center(

      child:
      Column(

        mainAxisSize:
        MainAxisSize.min,


        children: [


          Icon(

            Icons.design_services_outlined,

            size:80,

            color:
            Colors.grey,

          ),



          const SizedBox(
            height:15,
          ),



          const Text(

            "No services found",

            style:
            TextStyle(

              fontSize:18,

              fontWeight:
              FontWeight.bold,

            ),

          ),



          const SizedBox(
            height:5,
          ),



          const Text(
            "Create your first service",
          )


        ],

      ),

    );


  }


}