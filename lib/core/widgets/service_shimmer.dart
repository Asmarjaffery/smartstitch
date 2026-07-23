import 'package:flutter/material.dart';


class ServiceShimmer extends StatelessWidget {


  const ServiceShimmer({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return GridView.builder(

      padding:
      const EdgeInsets.all(16),


      itemCount:6,


      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount:2,

        childAspectRatio:.65,

      ),



      itemBuilder:(context,index){


        return Card(

          child:
          Column(

            children: [

              Expanded(

                child:
                Container(

                  color:
                  Colors.grey.shade300,

                ),

              ),



              Container(

                height:50,

                margin:
                const EdgeInsets.all(10),


                color:
                Colors.grey.shade300,

              )


            ],

          ),

        );


      },


    );


  }

}