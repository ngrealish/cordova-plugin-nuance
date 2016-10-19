cordova-plugin-nuance
======================

This is an implementation of Nuance SpeechKit (v2.1+) SDK in Cordova (6.2+).

###Installation

 `cordova plugin add cordova-plugin-nuance `

iOS

- Configure the plugin with your credentials in the Plugins/Credentials.m file

Android

- Configure the plugin with your credentials in the Plugins/Credentials.m file

###Usage

```javascript
NuancePlugin.initialize(
  function(success) {},
  function(error) {
    console.log('Nuance Initialization Error - ' + error.event_code);
  });

// ASR

var detection = 'long';
NuancePlugin.startRecognition(
  'dictation', // SKTransactionSpeechType: dictation, search & tv
  detection, // SKTransactionEndOfSpeechDetection: long, short or none
  'eng-USA',
  function(results) {

    // Wait until recognition is completed
    if (result.event == "RecoComplete") {

      // Check if results are empty
      if (results.returnCode == 0) {
        var results = (results.returnCode == 0) ? results.result : "No Results";

        // Stop recognition after it got results              
        if (detection != 'none') {
          NuancePlugin.stopRecognition(
            function() {},
            function() {});
        }
      } else {
        var results = (results.returnCode == 0) ? results.result : "";
      }
    }
  },
  function(error) {
    var results = 'Nuance Speech Recognition Error - ' + error.event_code;
  });

// TTS

NuancePlugin.playTTS(
  'Listen to this text',
  'eng-USA',
  '',
  function(success) {},
  function(error) {
    console.log('Nuance TTS Error - ' + error.event);
  });

 ```

### Quirks iOS
Make sure to add NSMicrophoneUsageDescription to your apps' .plist file.

### Quirks Android
The new run-time permission system from Android 6.0+ is supported.

### License
This plugin uses the MIT license. Please file an issue if you have any questions or if you'd like to share how you're using this plugin.
