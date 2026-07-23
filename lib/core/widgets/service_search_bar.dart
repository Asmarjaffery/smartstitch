import 'package:flutter/material.dart';
import 'package:smartstitch/artist/design/artist_services_controller.dart';



class ServiceSearchBar extends StatelessWidget {
  final ArtistServicesController controller;
  const ServiceSearchBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged:
      controller.updateSearch,
      decoration:
      InputDecoration(
        hintText:
        "Search services...",
        prefixIcon:
        const Icon(
          Icons.search,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
        ),
      ),
    );
  }
}