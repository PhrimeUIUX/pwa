// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

firebase.initializeApp({
 apiKey: "AIzaSyA3tvPnJN8hy3HksAFLDkMHDAC6wMeXS-Q",
  authDomain: "toda-pal.firebaseapp.com",
  databaseURL: "https://toda-pal-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "toda-pal",
  storageBucket: "toda-pal.firebasestorage.app",
  messagingSenderId: "599344409686",
  appId: "1:599344409686:web:ae1f18c90ac11007675ff7
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