import { TikTokLiveConnection } from 'tiktok-live-connector';
import { normalize } from './normalize.mjs';
import { likePhotos } from './like-photo.mjs';

export function adapter(gifts, assets, Connection = TikTokLiveConnection) {
  return (name, emit, terminal, metrics, reportActivity) => {
    const connection = new Connection(name, {
      enableExtendedGiftInfo: false, processInitialData: false,
      ...(process.env.SIGN_API_KEY ? { signApiKey: process.env.SIGN_API_KEY } : {}),
    });
    const photos = process.env.TEST_LIKES_PHOTO === 'true' ? likePhotos(emit, assets, metrics) : null;
    if (photos) connection.on('like', data => {
      const id=data?.common?.msgId ?? data?.msgId;
      if(id) reportActivity?.({id:'like:'+String(id),kind:'like',count:data.count??data.likeCount});
      void photos.accept(data);
    });
    for (const [eventName, kind] of [['chat','comment'], ['follow','follow'], ['gift','gift']]) {
      connection.on(eventName, data => {
        const event = normalize(kind, data, gifts, assets);
        if (event) {
          reportActivity?.(event);
          if (photos && kind === 'comment') return;
          if (!data.common?.msgId && !data.msgId) metrics.missingIds++; emit(event);
        }
        else if (kind === 'gift' && (Number(data?.giftType ?? data?.giftDetails?.giftType ?? data?.gift?.type) !== 1 || data?.repeatEnd)) metrics.unmappedGifts++;
      });
    }
    connection.on('error', () => terminal('ERROR'));
    connection.on('disconnected', () => terminal('DISCONNECTED'));
    connection.on('streamEnd', () => terminal('OFFLINE'));
    return { connect: () => connection.connect(), close: () => { photos?.close(); connection.disconnect(); } };
  };
}
