package com.gomes.nowplaying;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSession;
import android.media.session.MediaSessionManager;
import android.media.session.PlaybackState;
import android.service.notification.NotificationListenerService;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class NowPlayingListenerService extends NotificationListenerService {
    public static final String FIELD_ACTION = "com.gomes.nowplaying.action";
    public static final String FIELD_TOKEN = "com.gomes.nowplaying.token";
    public static final String FIELD_ICON = "com.gomes.nowplaying.icon";
    public static final String ACTION_POSTED = "posted";
    public static final String ACTION_REMOVED = "removed";

    private MediaSessionManager mediaSessionManager;
    private Map<MediaSession.Token, MediaController.Callback> activeCallbacks = new HashMap<>();

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        mediaSessionManager = (MediaSessionManager) getSystemService(Context.MEDIA_SESSION_SERVICE);
        ComponentName componentName = new ComponentName(this, NowPlayingListenerService.class);
        
        try {
            List<MediaController> controllers = mediaSessionManager.getActiveSessions(componentName);
            updateControllers(controllers);
            
            mediaSessionManager.addOnActiveSessionsChangedListener(new MediaSessionManager.OnActiveSessionsChangedListener() {
                @Override
                public void onActiveSessionsChanged(List<MediaController> controllers) {
                    updateControllers(controllers);
                }
            }, componentName);
        } catch (SecurityException e) {
            e.printStackTrace();
        }
    }

    private void updateControllers(List<MediaController> controllers) {
        for (MediaController controller : controllers) {
            MediaSession.Token token = controller.getSessionToken();
            if (!activeCallbacks.containsKey(token)) {
                MediaController.Callback callback = new MediaController.Callback() {
                    @Override
                    public void onPlaybackStateChanged(PlaybackState state) {
                        sendData(token, ACTION_POSTED);
                    }
                    @Override
                    public void onMetadataChanged(MediaMetadata metadata) {
                        sendData(token, ACTION_POSTED);
                    }
                };
                controller.registerCallback(callback);
                activeCallbacks.put(token, callback);
                sendData(token, ACTION_POSTED);
            }
        }
    }

    private void sendData(MediaSession.Token token, String action) {
        final Intent intent = new Intent(NowPlayingPlugin.ACTION);
        intent.putExtra(FIELD_ACTION, action);
        intent.putExtra(FIELD_TOKEN, token);
        // Samsung often strips icons anyway, and NowPlayingPlugin uses metadata images
        sendBroadcast(intent);
    }
}
