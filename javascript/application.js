import Rails from "@rails/ujs";
Rails.start();
import "@hotwired/turbo-rails";
import "controllers";
import "bootstrap";

console.log("✅ Application.js loaded successfully!");

let db;
const request = indexedDB.open("OfflineSubmissionsDB", 1);

request.onupgradeneeded = function (event) {
  console.log("IndexedDB upgrade needed...");
  db = event.target.result;
  if (!db.objectStoreNames.contains("submissions")) {
    console.log("Creating 'submissions' store...");
    db.createObjectStore("submissions", { keyPath: "id", autoIncrement: true });
  }
};

request.onsuccess = function (event) {
  db = event.target.result;
  console.log("IndexedDB opened successfully:", db);
  if (navigator.onLine) {
    syncDataWithServer();
  }
};

request.onerror = function (event) {
  console.error("IndexedDB error:", event.target.errorCode);
};

function storeLocally(data) {
  if (!db) {
    console.warn("Database not ready yet. Data will not be stored.");
    return;
  }
  console.log("Storing data in IndexedDB:", data);
  const transaction = db.transaction(["submissions"], "readwrite");
  const store = transaction.objectStore("submissions");
  const req = store.add({ data: data, timestamp: new Date().toISOString() });
  req.onsuccess = function () {
    console.log("Data successfully stored in IndexedDB.");
  };
  req.onerror = function (event) {
    console.error("Error storing data in IndexedDB:", event.target.error);
  };
}
window.storeLocally = storeLocally;

function syncDataWithServer() {
  if (!db) {
    console.warn("Database not ready yet. Cannot sync data.");
    return;
  }
  console.log("Syncing data from IndexedDB to server...");
  const transaction = db.transaction(["submissions"], "readonly");
  const store = transaction.objectStore("submissions");
  const req = store.getAll();
  req.onsuccess = function (event) {
    const unsyncedData = event.target.result;
    if (unsyncedData.length === 0) {
      console.log("No unsynced data found.");
      return;
    }
    fetch("/sync-endpoint", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ submissions: unsyncedData }),
    })
      .then((response) => {
        if (response.ok) {
          console.log("Data synced successfully.");
          clearLocalData();
        } else {
          console.error("Sync failed.");
        }
      })
      .catch((error) => console.error("Error syncing data:", error));
  };
  req.onerror = function () {
    console.error("Error fetching data from IndexedDB.");
  };
}

function clearLocalData() {
  if (!db) {
    console.warn("Database not ready yet. Cannot clear data.");
    return;
  }
  const transaction = db.transaction(["submissions"], "readwrite");
  const store = transaction.objectStore("submissions");
  store.clear();
  console.log("Cleared local IndexedDB storage after sync.");
}

window.addEventListener("offline", function () {
  console.log("You are offline. Your changes will be saved locally.");
});

window.addEventListener("online", function () {
  console.log("You are back online. Syncing data...");
  syncDataWithServer();
});

document.addEventListener("DOMContentLoaded", function () {
  const form = document.getElementById("offlineForm");
  if (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      const formData = {
        guid: document.getElementById("guid").value,
        phone_number: document.getElementById("phone_number").value,
        action: form.action,
      };
      if (navigator.onLine) {
        sendToServer(formData);
      } else {
        storeLocally(formData);
        alert("You are offline. Data saved and will be synced once you are back online.");
      }
    });
  }
  // Flash Message Fade-Out (after 5 seconds)
  setTimeout(() => {
    document.querySelectorAll(".flash-message").forEach((message) => {
      message.style.transition = "opacity 1s ease-out";
      message.style.opacity = "0";
      setTimeout(() => {
        message.remove();
      }, 1000);
    });
  }, 5000);
});

// Turbo load event for cross-browser session state retrieval
document.addEventListener("turbo:load", function () {
  console.log("✅ Turbo:load event triggered.");
  if (document.body.dataset.userSignedIn === "true") {
    fetch("/sync-session")
      .then(response => response.json())
      .then(data => {
        console.log("Session state retrieved:", data.session_state);
        // Use data.session_state to rehydrate your application state if needed
      })
      .catch(error => console.error("Error fetching session state:", error));
  }
});

// Function to update session state on the server
function updateSessionState(newState) {
  fetch("/sync-session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ session_state: JSON.stringify(newState) }),
  })
    .then(response => response.json())
    .then(data => console.log("Session state updated:", data))
    .catch(error => console.error("Error updating session state:", error));
}
window.updateSessionState = updateSessionState;

function sendToServer(data) {
  fetch("/sync-endpoint", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  })
    .then((response) => {
      if (response.ok) {
        console.log("Data sent successfully to server.");
        syncDataWithServer();
      } else {
        console.error("Sync failed.");
      }
    })
    .catch((error) => console.error("Error syncing data:", error));
}
window.syncDataWithServer = syncDataWithServer;

setInterval(function () {
  if (navigator.onLine) {
    syncDataWithServer();
  }
}, 5000);
