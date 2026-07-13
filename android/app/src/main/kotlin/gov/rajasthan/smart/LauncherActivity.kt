package gov.rajasthan.smart

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * VAPT: exported launcher trampoline — [MainActivity] stays exported=false.
 */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
        )
        finish()
    }
}
