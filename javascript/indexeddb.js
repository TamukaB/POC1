const DB_NAME = "OfflineApp";
const DB_VERSION = 1;
const STORE_NAME = "offlineSubmissions";

function openDatabase() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = function (event) {
            const db = event.target.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, { keyPath: "id", autoIncrement: true });
            }
        };

        request.onsuccess = function (event) {
            resolve(event.target.result);
        };

        request.onerror = function (event) {
            reject("IndexedDB error: " + event.target.errorCode);
        };
    });
}

async function saveOfflineData(data) {
    const db = await openDatabase();
    const transaction = db.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    store.add(data);
}

async function getOfflineData() {
    return new Promise(async (resolve) => {
        const db = await openDatabase();
        const transaction = db.transaction(STORE_NAME, "readonly");
        const store = transaction.objectStore(STORE_NAME);
        const request = store.getAll();

        request.onsuccess = function () {
            resolve(request.result);
        };

        request.onerror = function () {
            resolve([]);
        };
    });
}

async function clearOfflineData() {
    const db = await openDatabase();
    const transaction = db.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    store.clear();
}

// Export functions
export { saveOfflineData, getOfflineData, clearOfflineData };
