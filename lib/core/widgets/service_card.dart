import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/design/artist_services_controller.dart';

class ServiceCard extends StatelessWidget {

  final Map<String,dynamic> service;

  final ArtistServicesController controller;

  const ServiceCard({

    super.key,

    required this.service,

    required this.controller,

  });

  @override
  Widget build(BuildContext context) {

    final image =
        service["coverImageUrl"] ?? "";

    final name =
        service["serviceName"] ?? "Service";

    final category =
        service["categoryName"] ?? "";

    final price =
        service["startingPrice"] ?? 0;

    final rating =
        service["rating"] ?? 0;

    final status =
        service["status"] ?? "draft";




    return Card(

      clipBehavior:
      Clip.antiAlias,


      elevation:2,



      child:
      Column(


        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [



          Stack(

            children: [



              AspectRatio(

                aspectRatio:
                1,


                child:
                Image.network(

                  image,


                  fit:
                  BoxFit.cover,


                  errorBuilder:
                      (c,e,s)=>


                      Container(

                        color:
                        Colors.grey.shade300,

                        child:
                        const Icon(
                          Icons.image,
                        ),

                      ),

                ),

              ),





              Positioned(

                top:8,

                right:8,


                child:
                PopupMenuButton(


                  itemBuilder:(context)=>[


                    PopupMenuItem(

                      child:
                      const Text(
                        "Edit",
                      ),


                      onTap:(){

                        Future.delayed(
                          Duration.zero,
                              (){

                            Get.toNamed(
                              "/edit-service",
                              arguments:
                              service,
                            );


                          },
                        );


                      },

                    ),




                    PopupMenuItem(

                      child:
                      Text(
                        status=="published"
                            ?
                        "Move Draft"
                            :
                        "Publish",
                      ),


                      onTap:(){

                        controller
                            .togglePublish(

                          service["id"],

                          status,

                        );


                      },


                    ),





                    PopupMenuItem(

                      child:
                      const Text(
                        "Duplicate",
                      ),


                      onTap:(){

                        controller
                            .duplicateService(
                            service
                        );


                      },


                    ),





                    PopupMenuItem(

                      child:
                      const Text(
                        "Delete",
                      ),


                      onTap:(){

                        controller
                            .deleteService(
                          service["id"],
                        );


                      },

                    ),



                  ],


                ),

              ),




              Positioned(

                bottom:8,

                left:8,


                child:
                Container(

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:8,
                    vertical:4,
                  ),


                  decoration:
                  BoxDecoration(

                    color:
                    status=="published"
                        ?
                    Colors.green
                        :
                    Colors.orange,


                    borderRadius:
                    BorderRadius.circular(20),

                  ),


                  child:
                  Text(

                    status
                        .toString()
                        .capitalize!,

                    style:
                    const TextStyle(

                      color:
                      Colors.white,

                      fontSize:11,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),


                ),

              )



            ],


          ),






          Padding(

            padding:
            const EdgeInsets.all(10),


            child:
            Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,


              children: [



                Text(

                  name,


                  maxLines:1,


                  overflow:
                  TextOverflow.ellipsis,


                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),




                const SizedBox(
                  height:4,
                ),




                Text(

                  category,


                  style:
                  TextStyle(

                    fontSize:12,

                    color:
                    Colors.grey.shade600,

                  ),

                ),





                const SizedBox(
                  height:8,
                ),




                Row(

                  children: [


                    const Icon(
                      Icons.star,
                      size:16,
                    ),



                    Text(
                      rating.toString(),
                    ),



                    const Spacer(),



                    Text(

                      "Rs $price",

                      style:
                      const TextStyle(

                        fontWeight:
                        FontWeight.bold,

                      ),

                    )



                  ],

                ),






                const SizedBox(
                  height:6,
                ),





                Row(

                  children: [


                    const Icon(
                      Icons.shopping_bag,
                      size:15,
                    ),


                    const SizedBox(
                      width:4,
                    ),


                    Text(
                      "${service["ordersCount"] ?? 0} orders",
                      style:
                      const TextStyle(
                        fontSize:12,
                      ),
                    )

                  ],

                )



              ],


            ),



          )




        ],


      ),


    );

  }
}