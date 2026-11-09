#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "esp_err.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "smart_aquarium";

static esp_err_t initialize_nvs(void)
{
    esp_err_t result = nvs_flash_init();
    if (result == ESP_ERR_NVS_NO_FREE_PAGES || result == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_LOGW(TAG, "NVS requires recovery; erasing the NVS partition.");
        ESP_ERROR_CHECK(nvs_flash_erase());
        result = nvs_flash_init();
    }
    return result;
}

void app_main(void)
{
    ESP_LOGI(TAG, "Smart Aquarium firmware bootstrap starting.");
    ESP_ERROR_CHECK(initialize_nvs());

    ESP_LOGI(TAG, "NVS initialized successfully.");
    ESP_LOGW(TAG, "Hardware drivers are not configured yet; no sensors or actuators are active.");
    ESP_LOGI(TAG, "Next: confirm exact board and component models before assigning pins or enabling outputs.");

    /*
     * Keep this bootstrap intentionally safe.
     * Do not set pump/feeder GPIO outputs until the actual board, driver,
     * electrical ratings, and safe boot states have been reviewed.
     */
    for (;;) {
        vTaskDelay(pdMS_TO_TICKS(10000));
        ESP_LOGI(TAG, "Firmware alive; hardware integration pending.");
    }
}
