package com.vanq.florence

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import com.supabase.supabase_flutter.SupabaseAuthPlugin

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Forward deep link intent to Supabase for token extraction
        SupabaseAuthPlugin.onNewIntent(intent)
    }
}
