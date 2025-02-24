console.log("✅ Registration.js loaded");

document.addEventListener("DOMContentLoaded", function () {
  const registrationForm = document.getElementById("new_user"); 

  if (registrationForm) {
    registrationForm.addEventListener("submit", function (event) {
      event.preventDefault(); 

      if (typeof Modernizr !== "undefined") {
        const features = {
          webrtc: Modernizr.webrtc || false,
          indexedDB: Modernizr.indexeddb || false, 
          serviceWorker: Modernizr.serviceworker || false,
          canvas: Modernizr.canvas || false,
          cookies: Modernizr.cookies || false,
          localStorage: Modernizr.localstorage || false,
          touchevents: Modernizr.touchevents || false,
          webgl: Modernizr.webgl || false
        };

        const fingerprint = JSON.stringify(features);
        console.log("🔍 Modernizr fingerprint:", fingerprint);

        const fingerprintField = document.getElementById("device_fingerprint");
        if (fingerprintField) {
          fingerprintField.value = fingerprint;
          console.log("📌 Hidden field set to:", fingerprintField.value);
        } else {
          console.error("⚠️ Hidden field 'device_fingerprint' not found!");
        }

        registrationForm.submit();
      } else {
        console.error("❌ Modernizr is not loaded properly.");
      }
    });
  } else {
    console.error("⚠️ Registration form with id 'new_user' not found!");
  }
});
