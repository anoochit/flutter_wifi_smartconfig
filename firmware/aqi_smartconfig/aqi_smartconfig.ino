// include preferences
#include <Preferences.h>
Preferences prefs;

// include wifi
#include "WiFi.h"
String ssid;
String pss;

// include PMS7003
#include "PMS.h"
#include <SPI.h>
HardwareSerial SerialPMS(1);
PMS pms(SerialPMS);
PMS::DATA data;
#define RXD2 26
#define TXD2 25

// chip id
uint32_t chipId = 0;

void setup()
{
  Serial.begin(9600);

  // Show Chip id
  Serial.printf("ESP32 Chip model = %s Rev %d\n", ESP.getChipModel(), ESP.getChipRevision());
  Serial.print("Mac Address: ");
  Serial.println(WiFi.macAddress());

  delay(3000);

  // Init preferences
  prefs.begin("esp32", false);

  // Get ssid and password
  ssid = prefs.getString("ssid", "");
  pss = prefs.getString("pss", "");
  Serial.print("SSID = ");
  Serial.println(ssid);
  Serial.print("pss = ");
  Serial.println(pss);

  // Connect to WiFi
  WiFi.begin(ssid.c_str(), pss.c_str());
  delay(3500); // Wait for a while till ESP connects to WiFi

  if (WiFi.status() != WL_CONNECTED) // if WiFi is not connected
  {
    // Init WiFi as Station, start SmartConfig
    WiFi.mode(WIFI_AP_STA);
    WiFi.beginSmartConfig();

    // Wait for SmartConfig packet from mobile
    Serial.println("Waiting for SmartConfig.");
    while (!WiFi.smartConfigDone())
    {
      delay(500);
      Serial.print(".");
    }

    Serial.println("");
    Serial.println("SmartConfig received.");

    // Wait for WiFi to connect to AP
    Serial.println("Waiting for WiFi");
    while (WiFi.status() != WL_CONNECTED)
    {
      delay(500);
      Serial.print(".");
    }

    Serial.println("WiFi Connected.");

    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Initialize PMS device.
    SerialPMS.begin(9600, SERIAL_8N1, RXD2, TXD2);
    pms.passiveMode();

    // Read the connected WiFi SSID and password
    ssid = WiFi.SSID();
    pss = WiFi.psk();
    Serial.print("SSID:");
    Serial.println(ssid);
    Serial.print("PSS:");
    Serial.println(pss);

    // Store ssid, pss to flash
    Serial.println("Store SSID & PSS in Flash");
    prefs.putString("ssid", ssid);
    prefs.putString("pss", pss);
  }
  else
  {
    Serial.println("WiFi Connected");

    // Initialize PMS device.
    SerialPMS.begin(9600, SERIAL_8N1, RXD2, TXD2);
    pms.passiveMode();
  }
}

void loop()
{

  Serial.println("Waking up, wait 30 seconds for stable readings...");
  pms.wakeUp();
  delay(30000);

  Serial.println("Send read request...");
  pms.requestRead();

  Serial.println("Wait max. 1 second for read...");
  if (pms.readUntil(data))
  {
    Serial.print("PM 1.0 (ug/m3): ");
    Serial.println(data.PM_AE_UG_1_0);

    Serial.print("PM 2.5 (ug/m3): ");
    Serial.println(data.PM_AE_UG_2_5);

    Serial.print("PM 10.0 (ug/m3): ");
    Serial.println(data.PM_AE_UG_10_0);
  }
  else
  {
    Serial.println("No data.");
  }

  Serial.println("Going to sleep for 60 seconds.");
  pms.sleep();
  delay(60000);
}
