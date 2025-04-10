
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RingtoneSelectionPage extends StatelessWidget {
  const RingtoneSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: CommonAppBar(title: 'Ringtones', isBack: true),
      body: Consumer<SettingsViewmodel>(builder: (context, provider, child) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: provider.ringtoneList.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(6)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("${index+1}"),
                    Text(provider.ringtoneList[index].title),
                    InkWell(
                      onTap: () {
                        /*FlutterRingtonePlayer().play(
                          // android: AndroidSounds.notification,
                          // ios: IosSound(1023),

                          fromFile: provider.ringtoneList[index].path,
                          volume: 1.0,
                          looping: false,
                          asAlarm: false,
                        );*/
                        provider.playSound(provider.ringtoneList[index].path);
                      },
                        child: Icon(Icons.play_arrow),
                    )
                  ],
                ),
              ),
            ),
          ),),
      ),)
    );
  }
}
