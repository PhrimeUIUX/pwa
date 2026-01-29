// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBp6_fzqtLoGmIeSyg3vtrHyJJfxVg902c",
  authDomain: "ppc-toda.firebaseapp.com",
  projectId: "ppc-toda",
  storageBucket: "ppc-toda.firebasestorage.app",
  messagingSenderId: "462080229186",
  appId: "1:462080229186:web:be7b5e37e13c33e09392db",
  measurementId: "G-30S1M2THQW",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);

  self.registration.showNotification(
   payload.data["title"] ?? payload.notification?.title ?? '',
    {
      body: payload.data["body"] ?? payload.notification?.body ?? '',
      icon: "/icons/webiconsmall.png",
    }
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  const targetUrl = '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});

self.addEventListener("message", (event) => {
  if (!event.data || !event.data.type) return;

  if (event.data.type === "SHOW_OTP") {
    self.registration.showNotification("Ka-TODA", {
      body: event.data.body,
      icon: "/icons/webiconsmall.png",
      tag: "otp-notification",
      renotify: true,
    });
  }
});