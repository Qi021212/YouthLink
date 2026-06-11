import { notificationManager } from '@kit.NotificationKit';

export function scheduleNotification(caseId: string, title: string, time: number) {
  let request: notificationManager.NotificationRequest = {
    id: parseInt(caseId.slice(-8), 16), // 生成唯一ID
    content: {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: { title: '个案提醒', text: title }
    },
    deliveryTime: time,
    showDeliveryTime: true
  };
  notificationManager.publish(request);
}