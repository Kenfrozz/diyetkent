/* eslint max-len: ["error", { "code": 120 }] */
import {onDocumentCreated, onDocumentWritten}
  from "firebase-functions/v2/firestore";
import {onCall}
  from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();

// Yeni mesaj eklendiğinde push notification gönder
export const sendMessageNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    try {
      const messageData = event.data?.data();
      const chatId = event.params.chatId;
      const messageId = event.params.messageId;

      logger.info(
        `📤 Yeni mesaj: ${messageId} in chat: ${chatId}`,
      );

      if (!messageData) {
        logger.error("❌ Mesaj verisi bulunamadı");
        return;
      }

      const senderId: string | undefined = messageData.senderId;
      const text: string | undefined = messageData.text;
      if (!senderId || !text) {
        logger.error("❌ Eksik mesaj verileri", {senderId, text});
        return;
      }

      // Gönderen kullanıcının adı
      let senderName = "Bilinmeyen Kullanıcı";
      try {
        const senderDoc = await admin
          .firestore()
          .collection("users")
          .doc(senderId)
          .get();
        if (senderDoc.exists) {
          const senderData = senderDoc.data();
          senderName = senderData?.name ||
            senderData?.displayName ||
            senderData?.username ||
            senderData?.email?.split("@")[0] ||
            "Bilinmeyen Kullanıcı";
        }
      } catch (error) {
        logger.error("❌ Gönderen kullanıcı bilgisi alma hatası:", error);
      }

      // Grup mesajı mı?
      const isGroupMessage: boolean = messageData.isGroupMessage === true;
      if (isGroupMessage) {
        // Öncelik: messageData içindeki groupMembers
        let members: string[] | undefined = undefined;
        if (Array.isArray(messageData.groupMembers)) {
          members = messageData.groupMembers as string[];
        }
        let groupName: string | undefined;

        try {
          // chat dokümanından grup adını ve participants'ı getir
          const chatDoc = await admin
            .firestore()
            .collection("chats")
            .doc(chatId)
            .get();
          const chatData = chatDoc.data();
          if (chatData) {
            groupName = chatData.groupName || chatData.name;
            if (!members && Array.isArray(chatData.participants)) {
              members = chatData.participants as string[];
            }
          }
        } catch (e) {
          logger.warn("⚠️ Chat dokümanı okunamadı", e);
        }

        if (!members || members.length === 0) {
          logger.error("❌ Grup üyeleri bulunamadı, bildirim atlanıyor");
          return;
        }

        // Tüm üyelere (gönderen hariç) bildirim gönder
        const targets = members.filter((m) => m && m !== senderId);
        await Promise.all(
          targets.map((uid) =>
            sendNotificationToUser(uid, {
              title: groupName || "Yeni Grup Mesajı",
              body: `${senderName}: ${text}`,
              chatId,
              messageId,
              senderId,
            })
          )
        );

        logger.info(`✅ Grup bildirimi gönderildi: ${targets.length} üye`);
        return;
      }

      // Bireysel mesaj: recipientId beklenir
      const recipientId: string | undefined = messageData.recipientId;
      if (!recipientId) {
        logger.error("❌ recipientId yok, bireysel bildirim gönderilemedi");
        return;
      }

      await sendNotificationToUser(recipientId, {
        title: senderName,
        body: text,
        chatId,
        messageId,
        senderId,
      });

      logger.info("✅ Notification gönderimi tamamlandı");
    } catch (error) {
      logger.error("❌ Notification gönderme hatası:", error);
    }
  }
);

// Her iki kullanıcı da sohbeti sildiyse chati ve mesajlarını kalıcı sil
export const purgeChatIfBothDeleted = onDocumentWritten(
  "chats/{chatId}",
  async (event) => {
    try {
      const after = event.data?.after?.data();
      if (!after) return;
      const deletedFor = after.deletedFor as Record<string, boolean> | undefined;
      const participants = after.participants as string[] | undefined;
      if (!deletedFor || !participants || participants.length < 2) return;

      // Tüm katılımcılar için deletedFor true mu?
      const allDeleted = participants.every(
        (uid) => deletedFor[uid] === true,
      );
      if (!allDeleted) return;

      const chatId = event.params.chatId as string;
      // Önce messages alt koleksiyonunu sil
      const db = admin.firestore();
      const messagesRef = db
        .collection("chats")
        .doc(chatId)
        .collection("messages");
      const batchSize = 400;
      let lastDoc:
        FirebaseFirestore.QueryDocumentSnapshot | undefined = undefined;
      let hasMore = true;
      while (hasMore) {
        let query = messagesRef.orderBy("__name__").limit(batchSize);
        if (lastDoc) query = query.startAfter(lastDoc);
        const snap = await query.get();
        if (snap.empty) break;
        const batch = db.batch();
        snap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
        lastDoc = snap.docs[snap.docs.length - 1];
        hasMore = snap.size >= batchSize;
      }

      // Son olarak chat dokümanını sil
      await db.collection("chats").doc(chatId).delete();
      logger.info(`🧹 Chat purged: ${chatId}`);
    } catch (e) {
      logger.error("❌ purgeChatIfBothDeleted error", e);
    }
  }
);

// Süresi dolmuş story'leri pasifleştir (veya temizle)
export const cleanExpiredStories = onSchedule({
  schedule: "every 60 minutes",
  timeZone: "UTC",
}, async () => {
  try {
    const db = admin.firestore();
    const now = new Date();
    const snap = await db
      .collection("stories")
      .where("isActive", "==", true)
      .where("expiresAt", "<=", now)
      .get();

    if (snap.empty) {
      logger.info("🧹 cleanExpiredStories: temizlenecek story yok");
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.set(
        doc.ref,
        {
          isActive: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    });
    await batch.commit();
    logger.info(`🧹 cleanExpiredStories: ${snap.size} story pasifleştirildi`);
  } catch (e) {
    logger.error("❌ cleanExpiredStories error", e);
  }
});

/**
 * Kullanıcıya push notification gönder
 * @param {string} userId - Kullanıcı ID'si
 * @param {object} notificationData - Notification verisi
 */
async function sendNotificationToUser(
  userId: string,
  notificationData: {
    title: string;
    body: string;
    chatId: string;
    messageId: string;
    senderId: string;
  }
) {
  try {
    // Kullanıcının FCM token'ını al
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      logger.error(`❌ Kullanıcı bulunamadı: ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      logger.error(`❌ FCM token bulunamadı: ${userId}`);
      return;
    }

    // Notification payload hazırla
    const payload = {
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: {
        chatId: notificationData.chatId,
        messageId: notificationData.messageId,
        senderId: notificationData.senderId,
        senderName: notificationData.title, // Kullanıcı adını data'ya da ekle
        text: notificationData.body, // Mesaj metnini de ekle
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      token: fcmToken,
    };

    // FCM ile notification gönder
    const response = await admin.messaging().send(payload);
    logger.info(`✅ Notification gönderildi: ${userId} - ${response}`);
  } catch (error) {
    logger.error(`❌ Notification gönderme hatası (${userId}):`, error);
  }
}

// Test notification gönder
export const sendChatTestNotification = onCall(async (request) => {
  try {
    const userId = request.auth?.uid;
    const data = request.data;
    const targetUserId = data.targetUserId;
    const message = data.message || "Test mesajı";
    const chatId = data.chatId;

    if (!userId || !targetUserId || !chatId) {
      throw new Error("Gerekli parametreler eksik");
    }

    await sendNotificationToUser(targetUserId, {
      title: "Test Notification",
      body: message,
      chatId: chatId,
      messageId: "test_" + Date.now(),
      senderId: userId,
    });

    logger.info(`✅ Test notification gönderildi: ${targetUserId}`);
    return {success: true};
  } catch (error) {
    logger.error("❌ Test notification hatası:", error);
    throw new Error("Test notification başarısız");
  }
});
