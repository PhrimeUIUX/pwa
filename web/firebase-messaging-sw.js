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
    payload.notification?.title || "Background Title",
    {
      body: payload.notification?.body || "Background Body",
      icon: "/icons/webiconsmall.png",
    }
  );
});
