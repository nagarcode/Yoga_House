import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share/share.dart';
import 'package:yoga_house/Services/utils_file.dart';

import 'grid_button.dart';

class ContactButtonGreed extends StatelessWidget {
  const ContactButtonGreed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttons = _buttons(context);
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: buttons,
    );
  }

  List<Widget> _buttons(BuildContext context) {
    final theme = Theme.of(context);
    return [
      GridButton(
        text: 'טלפון',
        onClick: () => Utils.call(Utils.yuvishPhoneNoPrefix(), context),
        theme: theme,
        icon: Icons.phone,
      ),
      GridButton(
        text: 'WhatsApp',
        onClick: () =>
            Utils.launchWhatsapp('+972' + Utils.yuvishPhoneNoPrefix()),
        theme: theme,
        icon: FontAwesomeIcons.whatsapp,
      ),
      // GridButton(
      //     text: 'מיקום',
      //     onClick: () => _locationTapped(context),
      //     theme: theme,
      //     icon: Icons.location_on_outlined),
      GridButton(
        text: 'שתף',
        onClick: () => Share.share(Utils.appOneLink()),
        theme: theme,
        icon: Icons.ios_share_outlined,
      ),
      GridButton(
        text: 'אינסטגרם',
        onClick: () =>
            Utils.launchInstagram(Utils.adminInstagramUrl(), context),
        theme: theme,
        icon: Icons.camera_alt_outlined,
      ),
      // GridButton(
      //   text: 'אישי',
      //   onClick: () {},
      //   theme: theme,
      //   icon: Icons.person_outline_outlined,
      // ),
    ];
  }

  // _locationTapped(BuildContext context) async {
  // try {
  //     final coords = APIPath.adminNavigationCoords();
  //     final title = "Ocean Beach";
  //     final availableMaps = await MapLauncher.installedMaps;
  //     showModalBottomSheet(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return SafeArea(
  //           child: SingleChildScrollView(
  //             child: Container(
  //               child: Wrap(
  //                 children: <Widget>[
  //                   for (var map in availableMaps)
  //                     ListTile(
  //                       onTap: () => map.showMarker(
  //                         coords: coords,
  //                         title: title,
  //                       ),
  //                       title: Text(map.mapName),
  //                       leading: SvgPicture.asset(
  //                         map.icon,
  //                         height: 30.0,
  //                         width: 30.0,
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     print(e);
  //   }
  // }
}
