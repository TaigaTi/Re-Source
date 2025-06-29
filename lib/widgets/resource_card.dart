import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade100,
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
                ),
              ),
              Center(
                child: Text(
                  "Resource Title",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
