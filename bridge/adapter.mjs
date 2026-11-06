import { TikTokLiveConnection } from 'tiktok-live-connector';
import { portraits } from './portraits.mjs';
import { normalize } from './normalize.mjs';

export function adapter(gifts, assets, Connection = TikTokLiveConnection) {
  return (name, emit, terminal, metrics, reportActivity) => {
    const connection = new Connection(name, {
      enableExtendedGiftInfo: false, processInitialData: false,
      ...(process.env.SIGN_API_KEY ? { signApiKey: process.env.SIGN_API_KEY } : {}),
    });
    const painter=portraits(emit,metrics);
    for (const [eventName, kind] of [['chat','comment'], ['follow','follow'], ['gift','gift']]) {
      connection.on(eventName, data => {
        const event = normalize(kind, data, gifts, assets);
        if (event) {
          reportActivity?.(event);
          if (!data.common?.msgId && !data.msgId) metrics.missingIds++; painter.accept(event);
        }
        else if (kind === 'gift' && (Number(data?.giftType ?? data?.giftDetails?.giftType ?? data?.gift?.type) !== 1 || data?.repeatEnd)) metrics.unmappedGifts++;
      });
    }
    connection.on('error', () => terminal('ERROR'));
    connection.on('disconnected', () => terminal('DISCONNECTED'));
    connection.on('streamEnd', () => terminal('OFFLINE'));
    return { connect: () => connection.connect(), close: () => { painter.close(); connection.disconnect(); } };
  };
}
