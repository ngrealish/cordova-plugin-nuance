var exec = require("cordova/exec");


function NuanceSpeechKitPlugin() {}

// **Initialize speech kit**
//
// `credentialClassName`  The class name to be loaded to retrieve the app id and key
// `serverName`  The hostname of the server to connect to
// `port`  The port number for connection
// `sslEnabled`  True if SSL is enabled for the connection
// `successCallback`  The callback function for success
// `failureCallback`  The callback function for error
NuanceSpeechKitPlugin.prototype.initialize = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "initSpeechKit", []);
};

// **Starts speech recognition**
//
// `recoType`  Type of recognition (Dictation, Search or TV)
// `detection`  End of speech detection (Short, Long or None)
// `language`  Language code for recognition
// `successCallback`  The callback function for success
// `failureCallback`  The callback function for error
NuanceSpeechKitPlugin.prototype.startRecognition = function(recoType, detection, language,
  successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "startRecognition", [recoType, detection, language]);
};

//These two functions deal with checking status of recording

NuanceSpeechKitPlugin.prototype.hasRecordingStarted = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "recognizerDidBeginRecording", []);
};

NuanceSpeechKitPlugin.prototype.hasRecordingStopped = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "recognizerDidFinishRecording", []);
};

// **Stops speech recognition**
//
// `successCallback`  The callback function for success
// `failureCallback`  The callback function for error
NuanceSpeechKitPlugin.prototype.stopRecognition = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "stopRecognition", []);
};

// **Gets the last set of results from speech recognition**
//
// `successCallback` The callback function for success
// `failureCallback` The callback function for error
NuanceSpeechKitPlugin.prototype.getResults = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "getRecoResult", []);
};

// **Plays text using text to speech**
//
// `text` The text to play
// `language` Language code for TTS playback
// `voice` The voice to be used for TTS playback
// `successCallback`  The callback function for success
// `failureCallback`  The callback function for error
NuanceSpeechKitPlugin.prototype.playTTS = function(text, language, voice,
  successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "startTTS", [text, language, voice]);
};

// **Stops text to speech playback**
//
// `text` The text to play
// `language` Language code for TTS playback
// `voice` The voice to be used for TTS playback
// `successCallback`  The callback function for success
// `failureCallback`  The callback function for error
NuanceSpeechKitPlugin.prototype.stopTTS = function(successCallback, failureCallback) {
  exec(successCallback,
    failureCallback,
    "NuancePlugin",
    "stopTTS", []);
};

var NuancePlugin = new NuanceSpeechKitPlugin();
module.exports = NuancePlugin;
