let deferredPrompt;
const installBtn = document.getElementById("installPwa");

// Handle install prompt
window.addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault();
  deferredPrompt = e;
  
  installBtn.style.display = "block";
  installBtn.textContent = "Install";
  
  installBtn.onclick = async () => {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      console.log(`User response: ${outcome}`);
      deferredPrompt = null;
    }
  };
});

// Check if app is installed (cross-platform)
async function checkIfInstalled() {
  // Chrome/Android: check installed related apps
  if (navigator.getInstalledRelatedApps) {
    const relatedApps = await navigator.getInstalledRelatedApps();
    const found = relatedApps.some(
      (app) =>
      app.platform === "webapp" &&
      app.url.includes("manifest.json") // replace if your manifest has another path
    );
    if (found) {
      setOpenApp();
      return;
    }
  }

  // Fallback: detect if running as standalone
  if (
    window.matchMedia("(display-mode: standalone)").matches ||
    window.navigator.standalone === true
  ) {
    setOpenApp();
  }
}

// Change button to Open App
function setOpenApp() {
  installBtn.style.display = "block";
  installBtn.style.backgroundColor = "#1A73E8";
  installBtn.style.color = "#ffffff";
  installBtn.textContent = "Open App";
  installBtn.onclick = () => {
    // Open your PWA's start_url
    window.location.href = "https://ppc-toda.vercel.app/build/web/index.html";
  };
}

// Run check every 5s
setInterval(checkIfInstalled, 100);

// Also check immediately on page load
checkIfInstalled();