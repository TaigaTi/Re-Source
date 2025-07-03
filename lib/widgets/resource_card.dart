import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget {
  final double? height;
  final Color? color;
  const ResourceCard({super.key, this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: SizedBox(
        width: double.infinity, // take full width of column
        child: Container(
          padding: EdgeInsets.all(15),
          child: Column(
            spacing: 10,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(
                  image: AssetImage("assets/images/success.png"),
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                ),
              ),
              Center(
                child: Text(
                  "Resource Title",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
