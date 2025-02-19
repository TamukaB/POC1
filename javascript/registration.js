// Returns a canvas fingerprint as a Base64 data URL
function getCanvasFingerprint() {
  const canvas = document.createElement('canvas');
  canvas.width = 200;
  canvas.height = 50;
  const ctx = canvas.getContext('2d');

  ctx.textBaseline = 'top';
  ctx.font = "14px 'Arial'";

  ctx.fillStyle = "#f60";
  ctx.fillRect(125, 1, 62, 20);

  // Draw text with varying colors for uniqueness
  ctx.fillStyle = "#069";
  ctx.fillText("Hello, world!", 2, 15);
  ctx.fillStyle = "rgba(102, 204, 0, 0.7)";
  ctx.fillText("Hello, world!", 4, 17);

  return canvas.toDataURL();
}

console.log("Registration.js loaded");

document.addEventListener("DOMContentLoaded", function () {
  const registrationForm = document.getElementById("new_user");
  if (registrationForm) {
    registrationForm.addEventListener("submit", function (event) {
      event.preventDefault(); // Prevent immediate submission

      // Generate the canvas fingerprint
      const canvasFingerprint = getCanvasFingerprint();
      console.log("Canvas Fingerprint:", canvasFingerprint);

      // Set the fingerprint into the hidden field
      const fingerprintField = document.getElementById("device_fingerprint");
      if (fingerprintField) {
        fingerprintField.value = canvasFingerprint;
        console.log("Hidden field set to:", fingerprintField.value);
      } else {
        console.error("Hidden field 'device_fingerprint' not found!");
      }

      // Optional: delay submission by 500ms to observe the console logs
      setTimeout(() => {
        registrationForm.submit();
      }, 500);
    });
  } else {
    console.error("Registration form with id 'new_user' not found!");
  }
});
