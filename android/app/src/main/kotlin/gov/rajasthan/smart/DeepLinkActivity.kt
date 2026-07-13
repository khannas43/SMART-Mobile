package gov.rajasthan.smart

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * VAPT: exported entry for deep links / App Links only.
 * Forwards to non-exported [MainActivity] (Flutter).
 */
class DeepLinkActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        forwardIntent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        forwardIntent()
    }

    private fun forwardIntent() {
        val forward = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            data = intent.data
            intent.categories?.forEach { addCategory(it) }
            intent.extras?.let { putExtras(it) }
            addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK,
            )
        }
        startActivity(forward)
        finish()
    }
}
