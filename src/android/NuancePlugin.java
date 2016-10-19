
package com.lingusocial.nuance;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.Manifest;
import android.os.Build;
import android.os.Handler;
import android.util.Log;

import com.nuance.speechkit.*;

/**
 * Sample PhoneGap plugin to call Nuance Speech Kit
 *
 * @author asmyth
 */
public class NuancePlugin extends CordovaPlugin {

    /**
     * Action to initialize speech kit
     */
    public static final String ACTION_INIT = "initSpeechKit";

    /**
     * Action to start recognition
     */
    public static final String ACTION_START_RECO = "startRecognition";

    /**
     * Action to stop recognition
     */
    public static final String ACTION_STOP_RECO = "stopRecognition";

    /**
     * Action to get recognition results
     */
    public static final String ACTION_GET_RECO_RESULT = "getRecoResult";

    /**
     * Action to clean up speech kit after initialization
     */
    public static final String ACTION_CLEANUP = "cleanup";

    /**
     * Action to start TTS playback
     */
    public static final String ACTION_PLAY_TTS = "startTTS";

    /**
     * Action to stop TTS playback
     */
    public static final String ACTION_STOP_TTS = "stopTTS";

    /**
     * Action to setup a callback id to get the next event
     */
    public static final String ACTION_QUERY_NEXT_EVENT = "queryNextEvent";

    /**
     * Return code - success
     */
    public static final int RC_SUCCESS = 0;

    /**
     * Return code - failure
     */
    public static final int RC_FAILURE = -1;

    /**
     * Return code - speech kit not initialized
     */
    public static final int RC_NOT_INITIALIZED = -2;

    /**
     * Return code - speech recognition not started
     */
    public static final int RC_RECO_NOT_STARTED = -3;

    /**
     * Return code - no recognition result is available
     */
    public static final int RC_RECO_NO_RESULT_AVAIL = -4;

    /**
     * Return code - TTS playback was not started
     */
    public static final int RC_TTS_NOT_STARTED = -5;

    /**
     * Return code - recognition failure
     */
    public static final int RC_RECO_FAILURE = -6;

    /**
     * Return code TTS text is invalid
     */
    public static final int RC_TTS_TEXT_INVALID = -7;

    /**
     * Return code - TTS parameters are invalid
     */
    public static final int RC_TTS_PARAMS_INVALID = -8;

    /**
     * Call back event - Initialization complete
     */
    public static final String EVENT_INIT_COMPLETE = "InitComplete";

    /**
     * Call back event - clean up complete
     */
    public static final String EVENT_CLEANUP_COMPLETE = "CleanupComplete";

    /**
     * Call back event - Recognition started
     */
    public static final String EVENT_RECO_STARTED = "RecoStarted";

    /**
     * Call back event - Recognition compelte
     */
    public static final String EVENT_RECO_COMPLETE = "RecoComplete";

    /**
     * Call back event - Recognition stopped
     */
    public static final String EVENT_RECO_STOPPED = "RecoStopped";

    /**
     * Call back event - Processing speech recognition result
     */
    public static final String EVENT_RECO_PROCESSING = "RecoProcessing";

    /**
     * Call back event - Recognition error
     */
    public static final String EVENT_RECO_ERROR = "RecoError";

    /**
     * Call back event - Volume update while recording speech
     */
    public static final String EVENT_RECO_VOLUME_UPDATE = "RecoVolumeUpdate";

    /**
     * Call back event - TTS playback started
     */
    public static final String EVENT_TTS_STARTED = "TTSStarted";

    /**
     * Call back event - TTS playing
     */
    public static final String EVENT_TTS_PLAYING = "TTSPlaying";

    /**
     * Call back event - TTS playback stopped
     */
    public static final String EVENT_TTS_STOPPED = "TTSStopped";

    /**
     * Call back event - TTS playback complete
     */
    public static final String EVENT_TTS_COMPLETE = "TTSComplete";

    /**
     * Recognizer reference
     */
    private Transaction currentRecognizer = null;

    /**
     * Handler reference
     */
    private Handler handler = null;

    /**
     * Reference to last result
     */
    private Recognition lastResult = null;

    /**
     * State variable to track if recording is active
     */
    private boolean recording = false;

    /**
     * ID provided to invoke callback function.
     */
    private CallbackContext recognitionCallbackContext = null;


    private Transaction vocalizerInstance;

    /**
     * ID provided to invoke callback function.
     */
    private CallbackContext ttsCallbackContext = null;

    public CallbackContext callbackContext;

    private Session session;

    private JSONArray tmpData = null;

    /**
     * Method to initiate calls from PhoneGap/javascript API
     *
     * @param action     The action method
     * @param data       Incoming parameters
     * @param callbackId The call back id
     */
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;

        this.tmpData = data;
        this.callbackContext = callbackContext;

        try {
            if (ACTION_INIT.equals(action)) { // INITALIZE
                result = initSpeechKit(data, callbackContext);
            } else if (ACTION_START_RECO.equals(action)) { // START RECOGNITION
                if (Build.VERSION.SDK_INT >= 23) {
                    if (!this.cordova.hasPermission(Manifest.permission.RECORD_AUDIO)) {
                        this.cordova.requestPermission(this, 0, Manifest.permission.RECORD_AUDIO);
                    } else {
                        result = startRecognition(data, callbackContext);
                    }
                } else {
                    result = startRecognition(data, callbackContext);
                }
            } else if (ACTION_STOP_RECO.equals(action)) { // STOP RECOGNITION
                result = stopRecognition(data, callbackContext);
            } else if (ACTION_GET_RECO_RESULT.equals(action)) { // GET THE LAST RESULT
                result = getRecoResult(data, callbackContext);
            } else if (ACTION_PLAY_TTS.equals(action)) { // START TTS PLAYBACK
                result = startTTS(data, callbackContext);
            } else if (ACTION_STOP_TTS.equals(action)) { // STOP TTS PLAYBACK
                result = stopTTS(data, callbackContext);
            } else if (ACTION_QUERY_NEXT_EVENT.equals(action)) { // ADD CALLBACK FOR NEXT EVENT

                JSONObject returnObject = new JSONObject();
                ttsCallbackContext = callbackContext;

                setReturnCode(returnObject, RC_SUCCESS, "Query Success");
                result = new PluginResult(PluginResult.Status.OK, returnObject);
            } else {
                result = new PluginResult(PluginResult.Status.INVALID_ACTION);
            }
        } catch (JSONException jsonEx) {
            result = new PluginResult(PluginResult.Status.JSON_EXCEPTION);
        } catch (Exception e) {
            result = new PluginResult(PluginResult.Status.ERROR);
        }

        // Request permission during run-time
        if (Build.VERSION.SDK_INT >= 23) {
            if (this.cordova.hasPermission(Manifest.permission.RECORD_AUDIO)) {
                callbackContext.sendPluginResult(result);
            }
        } else {
            callbackContext.sendPluginResult(result);
        }

        return true;
    }

    /**
     * Method to initialize speech kit.
     *
     * @param data       The data object passed into exec
     * @param callbackId The callback id passed into exec
     * @return PluginResult
     * The populated PluginResult
     * @throws JSONException
     */
    private PluginResult initSpeechKit(JSONArray data, CallbackContext callbackContext) throws JSONException {
        Log.d("NuancePlugin", "NuancePlugin.initSpeechKit");

        PluginResult result;
        JSONObject returnObject = new JSONObject();
        try {
            // Initiate session
            this.session = Session.Factory.session(this.cordova.getActivity().getApplicationContext(), Credentials.SERVER_URI, Credentials.APP_KEY);

            setReturnCode(returnObject, RC_SUCCESS, "Init Success");
            returnObject.put("event", EVENT_INIT_COMPLETE);
            result = new PluginResult(PluginResult.Status.OK, returnObject);
            result.setKeepCallback(false);
        } catch (Exception e) {
            Log.e("NuancePlugin", "NuancePlugin.initSpeechKit: Error initalizing:" + e.getMessage(), e);
            setReturnCode(returnObject, RC_FAILURE, e.toString());
            result = new PluginResult(PluginResult.Status.OK, returnObject);
        }

        return result;
    }

    /**
     * Starts recognition.
     *
     * @param data
     * @param callbackId
     * @return
     * @throws JSONException
     */
    private PluginResult startRecognition(JSONArray data, CallbackContext callbackContext) throws JSONException {

        Log.d("NuancePlugin", "NuancePlugin.startRecognition");

        JSONObject returnObject = new JSONObject();
        if (session != null) {
            // Get cordova params
            String recoType = data.getString(0);
            String detection = data.getString(1);
            String language = data.getString(2);

            RecognitionType speechType = RecognitionType.DICTATION;
            if ("search".equalsIgnoreCase(recoType)) {
                speechType = RecognitionType.SEARCH;
            } else if ("tv".equalsIgnoreCase(recoType)) {
                speechType = RecognitionType.TV;
            }

            DetectionType eosDetection = DetectionType.Long;
            if ("short".equalsIgnoreCase(detection)) {
                eosDetection = DetectionType.Short;
            } else if ("none".equalsIgnoreCase(detection)) {
                eosDetection = DetectionType.None;
            }

            lastResult = null;
            recognitionCallbackContext = callbackContext;

            // Set options
            Transaction.Options options = new Transaction.Options();
            options.setRecognitionType(speechType);
            options.setDetection(eosDetection);
            options.setLanguage(new Language(language));

            // Start listening
            currentRecognizer = session.recognize(options, recoListener);

            setReturnCode(returnObject, RC_SUCCESS, "Reco Start Success");
            returnObject.put("event", EVENT_RECO_STARTED);
        } else {
            Log.e("NuancePlugin", "NuancePlugin.execute: Speech kit was null, initialize not called.");
            setReturnCode(returnObject, RC_NOT_INITIALIZED, "Reco Start Failure: Speech Kit not initialized.");
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
        result.setKeepCallback(true);
        return result;
    }

    /**
     * Stops recognition.
     *
     * @param data
     * @param callbackId
     * @return
     * @throws JSONException
     */
    private PluginResult stopRecognition(JSONArray data, CallbackContext callbackContext) throws JSONException {

        Log.d("NuancePlugin", "NuancePlugin.stopRecognition: Entered method.");

        JSONObject returnObject = new JSONObject();
        if (currentRecognizer != null) {
            // Stop the recognizer
            currentRecognizer.stopRecording();

            setReturnCode(returnObject, RC_SUCCESS, "Reco Stop Success");
            returnObject.put("event", EVENT_RECO_STOPPED);
        } else {
            Log.e("NuancePlugin", "NuancePlugin.execute: Recognizer was null, start not called.");
            setReturnCode(returnObject, RC_RECO_NOT_STARTED, "Reco Stop Failure: Recognizer not started.");
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
        return result;
    }

    /**
     * Retrieves recognition results from the previous recognition
     *
     * @param data
     * @param callbackId
     * @return
     * @throws JSONException
     */
    private PluginResult getRecoResult(JSONArray data, CallbackContext callbackContext) throws JSONException {

        Log.d("NuancePlugin", "NuancePlugin.getRecoResult");

        JSONObject returnObject = new JSONObject();
        if (lastResult != null) {
            setReturnCode(returnObject, RC_SUCCESS, "Success");
            returnObject.put("result", lastResult.getText());

            Log.d("NuancePlugin", "Result: " + lastResult.getText());
        } else {
            Log.d("NuancePlugin", "NuancePlugin.execute: Last result was null.");
            setReturnCode(returnObject, RC_RECO_NO_RESULT_AVAIL, "No result available.");
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
        return result;
    }

    /**
     * Sets the return code and text into the return object passed.
     *
     * @param returnObject
     * @param returnCode
     * @param returnText
     * @throws JSONException
     */
    private void setReturnCode(JSONObject returnObject, int returnCode, String returnText) throws JSONException {
        returnObject.put("returnCode", returnCode);
        returnObject.put("returnText", returnText);
    }

    Transaction.Listener recoListener = new Transaction.Listener() {

        @Override
        public void onStartedRecording(Transaction transaction) {

            Log.d("NuancePlugin", "Recording...");

            recording = true;
            try {
                JSONObject returnObject = new JSONObject();
                setReturnCode(returnObject, RC_SUCCESS, "Recording Started");
                returnObject.put("event", EVENT_RECO_STARTED);

                PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
                result.setKeepCallback(true);
                recognitionCallbackContext.sendPluginResult(result);
            } catch (JSONException je) {
                android.util.Log.e("NuancePlugin", "NuancePlugin: Recognizer.Listener.onRecordingBegin: Error setting return: " + je.getMessage(), je);
            }

            Runnable r = new Runnable() {
                public void run() {
                    if ((currentRecognizer != null) && (recording == true)) {
                        try {
                            JSONObject returnObject = new JSONObject();
                            returnObject.put("event", EVENT_RECO_VOLUME_UPDATE);
                            returnObject.put("volumeLevel", Float.toString(currentRecognizer.getAudioLevel()));

                            PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
                            result.setKeepCallback(true);

                            recognitionCallbackContext.sendPluginResult(result);
                        } catch (JSONException je) {
                            android.util.Log.e("NuancePlugin", "NuancePlugin: Recognizer.Listener.onRecordingDone: Error setting return: " + je.getMessage(), je);
                        }
                        handler.postDelayed(this, 500);
                    }

                }
            };

            //r.run();
        }

        @Override
        public void onFinishedRecording(Transaction transaction) {

            Log.d("NuancePlugin", "Processing...");

            recording = false;
            try {
                JSONObject returnObject = new JSONObject();
                setReturnCode(returnObject, RC_SUCCESS, "Processing");
                returnObject.put("event", EVENT_RECO_PROCESSING);

                PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
                result.setKeepCallback(true);
                recognitionCallbackContext.sendPluginResult(result);
            } catch (JSONException je) {
                android.util.Log.e("NuancePlugin", "NuancePlugin: Recognizer.Listener.onRecordingDone: Error setting return: " + je.getMessage(), je);
            }
        }

        @Override
        public void onRecognition(Transaction transaction, Recognition recognition) {

            currentRecognizer = null;
            lastResult = recognition;
            recording = false;

            String resultString = recognition.getText();
            JSONObject returnObject = new JSONObject();
            try {
                setReturnCode(returnObject, RC_SUCCESS, "Reco Success");
                returnObject.put("event", EVENT_RECO_COMPLETE);
                returnObject.put("result", resultString);
                returnObject.put("result", resultString);
            } catch (JSONException je) {
                Log.d("NuancePlugin", "Recognizer.Listener.onResults: Error storing results: " + je.getMessage(), je);
            }

            recognitionCallbackContext.success(returnObject);
            Log.d("NuancePlugin", "Recognizer.Listener Results = " + resultString);
        }

        @Override
        public void onSuccess(Transaction transaction, String s) {
            // Do nothing
        }

        @Override
        public void onError(Transaction transaction, String s, TransactionException e) {

            currentRecognizer = null;
            recording = false;

            String detail = e.getLocalizedMessage();

            JSONObject returnObject = new JSONObject();
            try {
                setReturnCode(returnObject, RC_RECO_FAILURE, "Reco Failure");
                returnObject.put("event", EVENT_RECO_ERROR);
                returnObject.put("result", detail);
            } catch (JSONException je) {
                Log.d("NuancePlugin", "Recognizer.Listener.onError: Error storing results: " + je.getMessage(), je);
            }

            recognitionCallbackContext.error(returnObject);
            Log.d("NuancePlugin", "Recognizer.Listener.onError: " + e);
        }
    };

    /**
     * Starts TTS playback.
     *
     * @param data
     * @param callbackId
     * @return
     * @throws JSONException
     */
    private PluginResult startTTS(JSONArray data, CallbackContext callbackContext) throws JSONException {

        Log.d("NuancePlugin", "NuancePlugin.startTTS");

        PluginResult result = null;
        JSONObject returnObject = new JSONObject();

        String ttsText = data.getString(0);
        String language = data.getString(1);
        String voice = data.getString(2);
        ttsCallbackContext = callbackContext;

        if ((ttsText == null) || ("".equals(ttsText))) {
            setReturnCode(returnObject, RC_TTS_TEXT_INVALID, "TTS Text Invalid");
        } else if ((language == null) && (voice == null)) {
            setReturnCode(returnObject, RC_TTS_PARAMS_INVALID, "Invalid language or voice.");
        } else if (session != null) {
            // Setup our TTS transaction options.
            Transaction.Options options = new Transaction.Options();
            options.setLanguage(new Language(language));

            if(voice.length() > 1) {
                options.setVoice(new Voice(voice));
            }

            // Start a TTS transaction
            vocalizerInstance = session.speakString(ttsText, options, new Transaction.Listener() {

                @Override
                public void onAudio(Transaction transaction, Audio audio) {

                    vocalizerInstance = null;
                }

                @Override
                public void onSuccess(Transaction transaction, String s) {
                    // Notification of a successful transaction. Nothing to do here.
                }

                @Override
                public void onError(Transaction transaction, String s, TransactionException e) {
                    Log.d("NuancePlugin", "Error: " + e.getMessage());
                    vocalizerInstance = null;
                }
            });

            setReturnCode(returnObject, RC_SUCCESS, "Success");
        } else {
            Log.e("NuancePlugin", "NuancePlugin.execute: Speech kit was null, initialize not called.");
            setReturnCode(returnObject, RC_NOT_INITIALIZED, "TTS Start Failure: Speech Kit not initialized.");
        }

        result = new PluginResult(PluginResult.Status.OK, returnObject);
        result.setKeepCallback(true);
        return result;
    }

    /**
     * Stops TTS playback
     *
     * @param data
     * @param callbackId
     * @return
     * @throws JSONException
     */
    private PluginResult stopTTS(JSONArray data, CallbackContext callbackContext) throws JSONException {

        Log.d("NuancePlugin", "NuancePlugin.stopTTS");

        JSONObject returnObject = new JSONObject();
        if (vocalizerInstance != null) {
            vocalizerInstance.cancel();
            setReturnCode(returnObject, RC_SUCCESS, "Success");
            returnObject.put("event", EVENT_TTS_COMPLETE);

        } else {
            setReturnCode(returnObject, RC_TTS_NOT_STARTED, "TTS Stop Failure: TTS not started.");
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK, returnObject);
        return result;
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {
        if (grantResults[0] == 0) {
            PluginResult result = null;
            result = startRecognition(tmpData, callbackContext);
            callbackContext.sendPluginResult(result);
        }
    }
}
