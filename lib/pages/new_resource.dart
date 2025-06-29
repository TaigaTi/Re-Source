import 'package:flutter/material.dart';
import 'package:re_source/pages/edit_resource.dart';
import 'package:re_source/widgets/back_title.dart';
import 'package:re_source/widgets/custom_appbar.dart';
import 'package:re_source/widgets/custom_drawer.dart';

class NewResource extends StatelessWidget {
  const NewResource({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            BackTitle(title: "Add Resource"),
            SizedBox(height: 15,),
            Card(
              color: Colors.blue.shade100,
              child: SizedBox(
                width: double.infinity, // take full width of column
                child: Container(
                  padding: EdgeInsets.all(35),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image(
                          image: AssetImage("assets/images/resource-holding.png"),
                          width: double.infinity,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Resource Link",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Paste Resource Link',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            FilledButton(
              onPressed: () => {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const EditResource(),
                    transitionDuration: Duration.zero, // 👈 No animation
                    reverseTransitionDuration: Duration.zero,
                  ),
                ),
              },
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(Size(double.infinity, 40)),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                ),
              ),
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
