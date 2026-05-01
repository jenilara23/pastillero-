// ============================================================
//  PillCare ESP32 - Conectividad WiFi via Bluetooth
//  Modelo: ESP32 clásico (ESP-WROOM-32)
//  Librería BT: BluetoothSerial (solo ESP32 clásico)
// ============================================================

#include <BluetoothSerial.h>
#include <WiFi.h>
#include <Preferences.h>  // Para guardar credenciales en memoria flash

// ── Verificación de compatibilidad ──────────────────────────
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
  #error "Bluetooth no está habilitado. Actívalo en menuconfig."
#endif

// ── Objetos globales ─────────────────────────────────────────
BluetoothSerial SerialBT;
Preferences     preferences;

// ── Configuración ────────────────────────────────────────────
const char* BT_DEVICE_NAME  = "PillCare-ESP32";  // Nombre visible desde el celular
const int   WIFI_TIMEOUT_MS = 15000;             // 15 segundos para conectar WiFi
const int   LED_PIN         = 2;                 // LED integrado del ESP32

// ── Variables de estado ──────────────────────────────────────
String  receivedData   = "";
bool    wifiConnected  = false;
String  savedSSID      = "";
String  savedPassword  = "";

// ============================================================
//  SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.println("\n🚀 [PillCare] Iniciando ESP32...");

  // ── Iniciar Bluetooth ──
  if (!SerialBT.begin(BT_DEVICE_NAME)) {
    Serial.println("❌ [BT] Error al iniciar Bluetooth");
    blinkError();
  } else {
    Serial.printf("✅ [BT] Bluetooth activo como: %s\n", BT_DEVICE_NAME);
  }

  // ── Cargar credenciales guardadas ──
  loadCredentials();

  // ── Si hay credenciales guardadas, intentar conectar ──
  if (savedSSID.length() > 0) {
    Serial.println("💾 [WiFi] Credenciales encontradas, intentando reconectar...");
    connectToWifi(savedSSID, savedPassword);
  } else {
    Serial.println("📡 [BT] Esperando credenciales WiFi desde la app...");
  }
}

// ============================================================
//  LOOP
// ============================================================
void loop() {
  // ── Leer datos enviados desde el celular por Bluetooth ──
  if (SerialBT.available()) {
    char c = SerialBT.read();

    if (c == '\n') {
      receivedData.trim();

      if (receivedData.length() > 0) {
        Serial.printf("📨 [BT] Recibido: %s\n", receivedData.c_str());
        processCommand(receivedData);
      }

      receivedData = "";
    } else {
      receivedData += c;
    }
  }

  // ── Verificar conexión WiFi periódicamente ──
  if (wifiConnected && WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    Serial.println("⚠️ [WiFi] Conexión perdida. Intentando reconectar...");
    digitalWrite(LED_PIN, LOW);
    connectToWifi(savedSSID, savedPassword);
  }

  delay(100);
}

// ============================================================
//  PROCESAR COMANDOS DESDE LA APP
//
//  Protocolo de mensajes (texto plano separado por |):
//    WIFI|<ssid>|<password>   → conectar al WiFi
//    STATUS                   → consultar estado
//    FORGET                   → borrar credenciales guardadas
// ============================================================
void processCommand(String data) {

  // ── Comando: WIFI|ssid|password ──
  if (data.startsWith("WIFI|")) {
    int firstPipe  = data.indexOf('|');
    int secondPipe = data.indexOf('|', firstPipe + 1);

    if (secondPipe == -1) {
      sendToBT("ERROR|Formato inválido. Usa: WIFI|ssid|password");
      return;
    }

    String ssid     = data.substring(firstPipe + 1, secondPipe);
    String password = data.substring(secondPipe + 1);

    ssid.trim();
    password.trim();

    if (ssid.length() == 0) {
      sendToBT("ERROR|El SSID no puede estar vacío");
      return;
    }

    Serial.printf("📶 [WiFi] Intentando conectar a: %s\n", ssid.c_str());
    sendToBT("CONNECTING|Conectando a " + ssid + "...");

    bool ok = connectToWifi(ssid, password);

    if (ok) {
      saveCredentials(ssid, password);
      sendToBT("WIFI_OK|" + ssid + "|" + WiFi.localIP().toString());
    } else {
      sendToBT("WIFI_FAIL|No se pudo conectar a " + ssid);
    }
  }

  // ── Comando: STATUS ──
  else if (data == "STATUS") {
    if (wifiConnected) {
      sendToBT("STATUS|CONNECTED|" + savedSSID + "|" + WiFi.localIP().toString());
    } else {
      sendToBT("STATUS|DISCONNECTED");
    }
  }

  // ── Comando: FORGET ──
  else if (data == "FORGET") {
    clearCredentials();
    WiFi.disconnect();
    wifiConnected = false;
    sendToBT("FORGET|OK|Credenciales borradas");
    Serial.println("🗑️ [WiFi] Credenciales borradas");
  }

  // ── Comando desconocido ──
  else {
    sendToBT("ERROR|Comando desconocido: " + data);
  }
}

// ============================================================
//  CONECTAR AL WIFI
// ============================================================
bool connectToWifi(String ssid, String password) {
  WiFi.disconnect(true);
  delay(500);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), password.c_str());

  Serial.print("⏳ [WiFi] Conectando");
  unsigned long startTime = millis();

  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - startTime > WIFI_TIMEOUT_MS) {
      Serial.println("\n❌ [WiFi] Tiempo de espera agotado");
      wifiConnected = false;
      digitalWrite(LED_PIN, LOW);
      return false;
    }
    delay(500);
    Serial.print(".");
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));  // Parpadeo mientras conecta
  }

  wifiConnected = true;
  savedSSID     = ssid;
  savedPassword = password;
  digitalWrite(LED_PIN, HIGH);  // LED fijo = conectado

  Serial.printf("\n✅ [WiFi] Conectado a: %s\n", ssid.c_str());
  Serial.printf("   IP: %s\n", WiFi.localIP().toString().c_str());
  Serial.printf("   RSSI: %d dBm\n", WiFi.RSSI());

  return true;
}

// ============================================================
//  GUARDAR / CARGAR / BORRAR CREDENCIALES EN FLASH
// ============================================================
void saveCredentials(String ssid, String password) {
  preferences.begin("pillcare", false);
  preferences.putString("ssid", ssid);
  preferences.putString("pass", password);
  preferences.end();
  Serial.println("💾 [Flash] Credenciales guardadas");
}

void loadCredentials() {
  preferences.begin("pillcare", true);
  savedSSID     = preferences.getString("ssid", "");
  savedPassword = preferences.getString("pass", "");
  preferences.end();

  if (savedSSID.length() > 0) {
    Serial.printf("💾 [Flash] Credenciales cargadas para: %s\n", savedSSID.c_str());
  }
}

void clearCredentials() {
  preferences.begin("pillcare", false);
  preferences.clear();
  preferences.end();
  savedSSID     = "";
  savedPassword = "";
}

// ============================================================
//  ENVIAR MENSAJE AL CELULAR POR BLUETOOTH
// ============================================================
void sendToBT(String message) {
  SerialBT.println(message);
  Serial.printf("📤 [BT] Enviado: %s\n", message.c_str());
}

// ============================================================
//  PARPADEO DE ERROR (LED)
// ============================================================
void blinkError() {
  for (int i = 0; i < 6; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }
}
