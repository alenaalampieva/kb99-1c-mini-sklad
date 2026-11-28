# Неделя 6 (kb99): имитация внешней системы для HTTP-сервиса "ОбменJSON" учебной конфигурации "Мини склад".
# 1) GET  - получает остатки товаров из 1С в JSON;
# 2) POST - отправляет в 1С поступление товара (JSON), 1С создает и проводит документ "Поступление".
# Запуск: правой кнопкой по файлу -> "Выполнить с помощью PowerShell".

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$base = "http://localhost/minisklad/hs/exchange"

# Учебная база: пользователь "Администратор" без пароля (в рабочей базе - отдельный пользователь с паролем!)
$pair = "{0}:{1}" -f "Администратор", ""
$auth = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth" }

Write-Host "=== 1. GET $base/stock?warehouse=Основной ===" -ForegroundColor Cyan
$stock = Invoke-RestMethod -Uri "$base/stock?warehouse=Основной" -Headers $headers -Method Get
$stock.items | Format-Table code, name, warehouse, quantity, price -AutoSize

Write-Host "=== 2. POST $base/receipt ===" -ForegroundColor Cyan
$body = @{
    warehouse = "Основной"
    items     = @(
        @{ code = "000000017"; quantity = 25; price = 3.5 }   # Резистор 10 кОм
        @{ code = "000000005"; quantity = 5;  price = 50 }    # Транзистор Philips 2N2369
    )
} | ConvertTo-Json -Depth 5
Write-Host "Отправляем:" $body
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$answer = Invoke-RestMethod -Uri "$base/receipt" -Headers $headers -Method Post `
    -ContentType "application/json; charset=utf-8" -Body $bytes
Write-Host "Ответ 1С:" -ForegroundColor Green
$answer | Format-List

Write-Host "=== 3. POST с ошибкой (неизвестный код товара) ===" -ForegroundColor Cyan
$bad = @{ warehouse = "Основной"; items = @(@{ code = "999999999"; quantity = 1; price = 1 }) } | ConvertTo-Json -Depth 5
try {
    Invoke-RestMethod -Uri "$base/receipt" -Headers $headers -Method Post `
        -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($bad))
} catch {
    Write-Host "HTTP" $_.Exception.Response.StatusCode.value__ ":" $_.ErrorDetails.Message -ForegroundColor Yellow
}

Read-Host "Нажмите Enter, чтобы закрыть окно"
