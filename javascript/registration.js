console.log("Registration.js loaded");

function getAudioFingerprint(callback) {
  try {
    const AudioContext = window.OfflineAudioContext || window.webkitOfflineAudioContext;
    if (!AudioContext) {
      callback("NoAudioContext");
      return;
    }
    const context = new AudioContext(1, 44100, 44100);
    
    const oscillator = context.createOscillator();
    oscillator.type = "triangle";
    oscillator.frequency.value = 10000;
    
    const compressor = context.createDynamicsCompressor();
    compressor.threshold.value = -50;
    compressor.knee.value = 40;
    compressor.ratio.value = 12;
    compressor.attack.value = 0;
    compressor.release.value = 0.25;
    
    oscillator.connect(compressor);
    compressor.connect(context.destination);
    
    oscillator.start(0);
    context.startRendering().then(function(renderedBuffer) {
      let fingerprint = "";
      const channelData = renderedBuffer.getChannelData(0);
      for (let i = 0; i < channelData.length; i++) {
        fingerprint += channelData[i].toString();
      }
      callback(fingerprint);
    }).catch(function(err) {
      console.error("Audio rendering failed:", err);
      callback("Error");
    });
  } catch (e) {
    console.error("Audio fingerprinting failed", e);
    callback("Error");
  }
}

document.addEventListener("DOMContentLoaded", function () {
  const registrationForm = document.getElementById("new_user");
  if (registrationForm) {
    registrationForm.addEventListener("submit", function (event) {
      event.preventDefault(); 
      
      getAudioFingerprint(function(audioFingerprint) {
        console.log("Audio Fingerprint:", audioFingerprint);
        
        const fingerprintField = document.getElementById("audio_fingerprint");
        if (fingerprintField) {
          fingerprintField.value = audioFingerprint;
          console.log("Audio fingerprint field set to:", fingerprintField.value);
        } else {
          console.error("Hidden field 'audio_fingerprint' not found!");
        }
        
        registrationForm.submit();
      });
    });
  } else {
    console.error("Registration form with id 'new_user' not found!");
  }
});
