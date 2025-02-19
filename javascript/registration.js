console.log("Registration.js loaded");

document.addEventListener("DOMContentLoaded", function () {
    const registrationForm = document.getElementById("new_user");
    if (registrationForm) {
        registrationForm.addEventListener("submit", function (event) {
          event.preventDefault();  

          FingerprintJS.load().then(fp => {
            fp.get().then(result => {
                const visitorId = result.visitorId;  
                console.log("Device Fingerprint:", visitorId);

                const fingerprintField = document.getElementById("device_fingerprint");
                if (fingerprintField) {
                    fingerprintField.value = visitorId; 
                }

                registrationForm.submit();  
              });
          });
        });
    }
});
