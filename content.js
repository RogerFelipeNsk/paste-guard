console.log("🚀 Paste Guard: content script injetado!");

let isHandlingPaste = false; // controle de execução única

function containsSensitiveData(text) {
  const patterns = [
    // API keys e secrets (melhorados)
    /\bapi[_-]?key\b\s*[:=]?\s*['"]?[a-z0-9_\-]{16,}['"]?/i,
    /\b(secret|token|access[_-]?token|auth[_-]?token|refresh[_-]?token)\b\s*[:=]?\s*['"]?[a-z0-9_\-]{10,}['"]?/i,
    /\bbearer\s+[a-z0-9\-_\.=]{10,}/i,
    /\b(client[_-]?secret|app[_-]?secret|application[_-]?secret)\b\s*[:=]?\s*['"]?[a-z0-9_\-]{10,}['"]?/i,
  
    // Senhas e usuários (expandidos)
    /\b(password|passwd|pwd|pass|senha)\b\s*[:=]?\s*['"]?.{4,}['"]?/i,
    /\b(user(name)?|uid|login|email)\b\s*[:=]?\s*['"]?.+['"]?/i,
    /\b(admin|administrator|root)\b\s*[:=]?\s*['"]?.+['"]?/i,
  
    // AWS keys (expandidos)
    /AKIA[0-9A-Z]{16}/,
    /ASIA[0-9A-Z]{16}/,
    /A3T[A-Z0-9]{13}/,
    /AROA[A-Z0-9]{13}/,
    /AIDA[A-Z0-9]{13}/,
    /\baws[_-]?secret[_-]?access[_-]?key\b\s*[:=]?\s*['"]?[a-z0-9/+=]{40}['"]?/i,
    /\baws[_-]?session[_-]?token\b\s*[:=]?\s*['"]?[a-z0-9/+=]{100,}['"]?/i,
  
    // Azure & Microsoft
    /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i, // Azure Client ID
    /\b[a-z0-9]{32,34}\b/i, // Azure secrets (case insensitive)
    /\btenant[_-]?id\b\s*[:=]?\s*['"]?[0-9a-f-]{36}['"]?/i,
  
    // Google Cloud Platform
    /\bAIza[0-9A-Za-z\-_]{35}/,
    /\b[0-9]+-[a-z0-9_]{32}\.apps\.googleusercontent\.com/,
    /\bservice[_-]?account\b.*?"private_key"/i,
    /\b"type":\s*"service_account"/,
  
    // GitHub & GitLab tokens
    /\bgh[pousr]_[A-Za-z0-9_]{36,251}/,  // GitHub tokens
    /\bglpat-[a-zA-Z0-9_\-]{20}/,        // GitLab tokens
    /\bgho_[A-Za-z0-9_]{36}/,            // GitHub OAuth
    /\bghs_[A-Za-z0-9_]{36}/,            // GitHub server-to-server
  
    // Docker Hub
    /\bdckr_pat_[a-zA-Z0-9_-]{59}/,
  
    // Slack tokens
    /\bxox[bpars]-[0-9a-zA-Z-]{10,48}/,
  
    // Discord
    /\b[MN][A-Za-z\d]{23}\.[A-Za-z\d-_]{6}\.[A-Za-z\d-_]{27}/,
    /\bmfa\.[a-z0-9_\-]{84}/i,
  
    // Connection strings (expandidos)
    /["']?(DRIVER|Server|Data Source|Initial Catalog)=.*?;/i,
    /UID=.*?;.*?(PWD|Password)=.*?;/i,
    /(postgres|mysql|mongodb|sqlserver|redis|oracle|sqlite):\/\/[^ \n\r\t]+/i,
    /\bhost\s*[:=]\s*['"]?.+?['"]?;?\s*port\s*[:=]\s*['"]?\d+['"]?/i,
    /\bmongodb(\+srv)?:\/\/[^ \n\r\t]+/i,
    /\bredis:\/\/[^ \n\r\t]+/i,
  
    // SSH, RSA, TLS, Certificates
    /-----BEGIN [A-Z ]+-----[\s\S]*?-----END [A-Z ]+-----/,
    /\bssh-rsa\s+[A-Za-z0-9+/=]{100,}/,
    /\bssh-ed25519\s+[A-Za-z0-9+/=]{43,}/,
    /\becdsa-sha2-nistp\d+\s+[A-Za-z0-9+/=]{100,}/,
  
    // JWT tokens (melhorado)
    /\b(jwt|eyJ)[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]*/, // JWT
  
    // Stripe
    /\bsk_live_[0-9a-zA-Z]{24}/,
    /\bsk_test_[0-9a-zA-Z]{24}/,
    /\bpk_live_[0-9a-zA-Z]{24}/,
    /\bpk_test_[0-9a-zA-Z]{24}/,
  
    // PayPal
    /\bA[0-9A-Z]{32}/,
    /\bEP[0-9A-Z]{32}/,
  
    // Twilio
    /\bAC[a-z0-9]{32}/,
    /\bSK[a-z0-9]{32}/,
  
    // SendGrid
    /\bSG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}/,
  
    // Mailgun
    /\bkey-[0-9a-f]{32}/,
  
    // Heroku
    /\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/,
  
    // API Keys genéricos com padrões comuns
    /\b(key|secret|token|apikey|api_key)\b\s*[:=]?\s*['"]?[a-z0-9\-_]{20,}['"]?/i,
    /\b[a-z0-9]{32}\b/i, // Hash MD5-like
    /\b[a-f0-9]{40}\b/i, // Hash SHA1-like
    /\b[a-f0-9]{64}\b/i, // Hash SHA256-like
  
    // Padrões de configuração e credenciais
    /\b(conn(?:ection)?[_-]?str(?:ing)?|database[_-]?url|db[_-]?url)\b\s*[:=]/i,
    /\b(private[_-]?key|public[_-]?key|cert(?:ificate)?)\b\s*[:=]/i,
    /\b(webhook[_-]?url|callback[_-]?url|redirect[_-]?uri)\b\s*[:=]/i,
    /\b(smtp[_-]?password|mail[_-]?password|email[_-]?password)\b\s*[:=]/i,
  
    // Padrões suspeitos de URLs com credenciais
    /https?:\/\/[^:]+:[^@]+@[^\/\s]+/i,
    /ftp:\/\/[^:]+:[^@]+@[^\/\s]+/i,
  
    // Environment variables suspeitas
    /\b(ENV|ENVIRONMENT|CONFIG)\b.*?(password|secret|key|token)/i,
    /\b[A-Z_]{3,}_(PASSWORD|SECRET|KEY|TOKEN|API)\b/,
  
    // Credit card patterns (básico)
    /\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3[0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b/,
  
    // IPs privados com porta (possíveis endpoints internos)
    /\b(?:10\.|172\.(?:1[6-9]|2[0-9]|3[01])\.|192\.168\.)\d{1,3}\.\d{1,3}:\d+\b/,
  
    // Padrões específicos de arquivos de configuração
    /\[\s*(database|db|mysql|postgres|redis|mongodb)\s*\]/i,
    /\bDSN\s*[:=]/i,
    /\bJDBC_URL\s*[:=]/i
  ];
  
  return patterns.some((regex) => regex.test(text));
}

function getMessage(key) {
  return chrome.i18n.getMessage(key);
}

function handlePasteEvent(event) {
  if (isHandlingPaste) return;
  isHandlingPaste = true;

  const pastedText = (event.clipboardData || window.clipboardData).getData(
    "text"
  );

  if (containsSensitiveData(pastedText)) {
    const shouldPaste = confirm(getMessage("pasteWarning"));

    if (!shouldPaste) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }

  setTimeout(() => {
    isHandlingPaste = false;
  }, 50);
}

function bindPasteListeners() {
  document.addEventListener("paste", handlePasteEvent, true);

  const observer = new MutationObserver(() => {
    document
      .querySelectorAll('input, textarea, [contenteditable="true"]')
      .forEach((el) => {
        if (!el.hasAttribute("data-paste-guard")) {
          el.setAttribute("data-paste-guard", "true");
          el.addEventListener("paste", handlePasteEvent, true);
        }
      });
  });

  observer.observe(document.body, { childList: true, subtree: true });
}

bindPasteListeners();
