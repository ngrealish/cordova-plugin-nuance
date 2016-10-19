package com.lingusocial.nuance;

import android.net.Uri;

public class Credentials {

	public static final String APP_KEY = "";

	public static final String APP_ID = "";

	public static final String SERVER_HOST = "sslsandbox.nmdp.nuancemobility.net";

	public static final String SERVER_PORT = "443";

	public static final Uri SERVER_URI = Uri.parse("nmsps://" + APP_ID + "@" + SERVER_HOST + ":" + SERVER_PORT);
}
