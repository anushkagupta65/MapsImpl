// lib/presentation/widgets/custom_autocomplete_textfield.dart
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:map_assessment/src/utils/app_constants.dart';

class CustomAutoCompleteTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(Prediction) onPlaceSelected;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final Color? fillColor;

  const CustomAutoCompleteTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onPlaceSelected,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: controller,
      googleAPIKey: AppConstants.googleApiKey,
      inputDecoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: fillColor ?? Theme.of(context).cardColor,
        prefixIcon: prefixIcon,
        suffixIcon:
            suffixIcon != null
                ? IconButton(icon: suffixIcon!, onPressed: onSuffixIconTap)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // No border for a cleaner look
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ), // Highlight when focused
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ),
      ),
      debounceTime: 400,
      countries: const ["IN"],
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) {
        onPlaceSelected(prediction);
      },
      itemClick: (Prediction prediction) {
        controller.text = prediction.description ?? '';
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description?.length ?? 0),
        );
      },
      seperatedBuilder: const Divider(),
      containerHorizontalPadding: 10,
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(prediction.description ?? "")),
            ],
          ),
        );
      },
      isCrossBtnShown: true,
    );
  }
}
