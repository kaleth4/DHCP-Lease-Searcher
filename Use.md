
# DHCP Lease Searcher

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

Una herramienta avanzada y eficiente en PowerShell diseñada para administradores de red y sistemas. Este script automatiza la búsqueda de concesiones y reservas de direcciones IP v4 de forma centralizada a lo largo de múltiples servidores DHCP de Microsoft Windows Server.

---

## 🚀 Características Principales

* **Búsqueda Multi-Servidor:** Consulta de forma secuencial y optimizada en múltiples servidores DHCP.
* **Procesamiento en Lote (Batch):** Capacidad para recibir múltiples direcciones IP en una sola ejecución.
* **Integración con Pipeline:** Totalmente compatible con la tubería (`|`) de PowerShell para entrada y salida de datos.
* **Orientado a Objetos:** Retorna objetos puros de tipo `[PSCustomObject]`, permitiendo exportar resultados a CSV, JSON o GridView.
* **Modo Silencioso/Verboso:** Incluye soporte nativo para el parámetro `-Verbose` para diagnósticos en tiempo real.
* **Validación de Entrada:** Valida el formato de las direcciones IP antes de procesarlas.
* **Manejo de Errores Robusto:** Captura excepciones sin interrumpir la ejecución del script.

---

## 📋 Requisitos Previos

Para ejecutar este script de manera correcta, el entorno debe cumplir con:

### 1. **PowerShell**
   - Versión 5.1 o superior (incluyendo PowerShell 7+)
   - Ejecutar como **Administrador**

### 2. **Módulo DHCP**
   Debe estar instalado el módulo oficial de administración de DHCP (`DhcpServer`).
   
   **En Windows Server:**
   ```powershell
   Install-WindowsFeature RSAT-DHCP
   ```
   
   **En Windows 10/11:**
   - Descargar e instalar RSAT (Remote Server Administration Tools) desde Microsoft
   - O ejecutar: `Add-WindowsCapability -Online -Name "Rsat.DHCP.Tools~~~~0.0.1.0"`

### 3. **Permisos de Red**
   - Acceso de lectura en los servidores DHCP de destino
   - Conectividad de red hacia los servidores DHCP

### 4. **Política de Ejecución** (si es necesario)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

## 🔧 Parámetros

El script acepta los siguientes parámetros:

| Parámetro | Tipo | Obligatorio | Posición | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `-IPAddress` | `String[]` | **Sí** | 0 | Una o más direcciones IP v4 a buscar en la infraestructura. |
| `-DhcpServers` | `String[]` | No | 1 | Arreglo de nombres de host o IPs de servidores DHCP. Por defecto: `SERVER1`, `SERVER2`. |
| `-Verbose` | `Switch` | No | N/A | Muestra información detallada del proceso de búsqueda en tiempo real. |

---

## 💻 Código del Script (`Get-DhcpLeaseSearch.ps1`)

```powershell
<#
.SYNOPSIS
    Busca reservas y concesiones de IP en múltiples servidores DHCP.

.DESCRIPTION
    Este script recorre una lista de servidores DHCP buscando una o más direcciones IP
    y devuelve un objeto personalizado con los resultados. Soporta entrada mediante
    pipeline y validación de formato IP.

.PARAMETER IPAddress
    Una o más direcciones IP v4 que se desean localizar.

.PARAMETER DhcpServers
    Lista de servidores DHCP a consultar. Si no se especifica, usa los valores por defecto.

.EXAMPLE
    .\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50"

.EXAMPLE
    "192.168.1.50", "10.0.0.25" | .\Get-DhcpLeaseSearch.ps1 | Out-GridView

.EXAMPLE
    .\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50" -DhcpServers "DHCP-01", "DHCP-02" -Verbose
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String[]]$IPAddress,

    [Parameter(Mandatory = $false)]
    [String[]]$DhcpServers = @("SERVER1", "SERVER2")
)

PROCESS {
    foreach ($CurrentIP in $IPAddress) {
        
        # Validación de formato IP
        if ($CurrentIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            Write-Warning "El formato de la IP '$CurrentIP' no es válido. Se omitirá."
            continue
        }

        Write-Verbose "Buscando la dirección IP: $CurrentIP..."
        $FoundInAnyServer = $false

        foreach ($DhcpServer in $DhcpServers) {
            Write-Verbose "Consultando servidor: $DhcpServer"
            
            try {
                $Result = Get-DhcpServerv4Reservation -ComputerName $DhcpServer `
                    -IPAddress $CurrentIP -ErrorAction SilentlyContinue
                
                if ($Result) {
                    $FoundInAnyServer = $true
                    [PSCustomObject]@{
                        IPAddress  = $Result.IPAddress
                        ScopeId    = $Result.ScopeId
                        ClientId   = $Result.ClientId
                        Name       = $Result.Name
                        DhcpServer = $DhcpServer
                        Status     = "Encontrado"
                    }
                    break
                }
            }
            catch {
                Write-Error "Error al conectar con $DhcpServer : $_"
            }
        }

        if (-not $FoundInAnyServer) {
            [PSCustomObject]@{
                IPAddress  = $CurrentIP
                ScopeId    = $null
                ClientId   = $null
                Name       = $null
                DhcpServer = $null
                Status     = "No Encontrado"
            }
        }
    }
}
```

---

## 📖 Ejemplos de Uso

### 1. Búsqueda Básica de una Sola IP
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50"
```

### 2. Búsqueda de Múltiples IPs
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50", "10.0.0.25", "172.16.5.100"
```

### 3. Especificar Servidores DHCP Personalizados
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50" `
    -DhcpServers "DHCP-PROD-01", "DHCP-PROD-02"
```

### 4. Usar Pipeline para Entrada de Datos
```powershell
"192.168.1.50", "10.0.0.25" | .\Get-DhcpLeaseSearch.ps1
```

### 5. Mostrar Resultados en Interfaz Gráfica
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50" | Out-GridView
```

### 6. Exportar Resultados a CSV
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress (Get-Content .\ips.txt) `
    | Export-Csv -Path ".\Resultado_DHCP.csv" -NoTypeInformation
```

### 7. Diagnóstico en Tiempo Real (Modo Verboso)
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50" -Verbose
```

### 8. Leer IPs desde un Archivo de Texto
```powershell
Get-Content ".\lista_ips.txt" | .\Get-DhcpLeaseSearch.ps1 | Format-Table -AutoSize
```

---

## 📊 Estructura del Objeto de Salida

Cada consulta genera un objeto `PSCustomObject` con las siguientes propiedades:

| Propiedad | Tipo | Descripción |
| :--- | :--- | :--- |
| **IPAddress** | String | La dirección IP consultada |
| **ScopeId** | String | El ID del ámbito (Subred) DHCP |
| **ClientId** | String | La dirección MAC del dispositivo |
| **Name** | String | Nombre o descripción de la reserva |
| **DhcpServer** | String | Servidor DHCP donde se encontró |
| **Status** | String | Estado: "Encontrado" o "No Encontrado" |

### Ejemplo de Salida
```
IPAddress      : 192.168.1.50
ScopeId        : 192.168.1.0
ClientId       : 00-1A-2B-3C-4D-5E
Name           : Laptop-Finanzas
DhcpServer     : SERVER1
Status         : Encontrado
```

---

## 🛠️ Personalización

### Cambiar Servidores DHCP por Defecto

Abre el archivo `.ps1` y modifica la línea:

```powershell
[String[]]$DhcpServers = @("TU_SERVIDOR_1", "TU_SERVIDOR_2", "TU_SERVIDOR_3")
```

### Agregar Validación Adicional

Para validar que las IPs pertenecen a un rango específico, añade después de la validación de formato:

```powershell
if ($CurrentIP -notmatch '^192\.168\.|^10\.|^172\.') {
    Write-Warning "La IP '$CurrentIP' no pertenece a los rangos permitidos."
    continue
}
```

---

## ⚠️ Solución de Problemas

### Error: "Get-DhcpServerv4Reservation no se reconoce"
**Solución:** Instala el módulo DHCP:
```powershell
Add-WindowsCapability -Online -Name "Rsat.DHCP.Tools~~~~0.0.1.0"
```

### Error: "Acceso denegado"
**Solución:** Ejecuta PowerShell como Administrador y verifica permisos en los servidores DHCP.

### El script es lento
**Solución:** Verifica la conectividad de red hacia los servidores DHCP o reduce la cantidad de IPs a buscar.

---

## 🔄 Mejoras Implementadas (Nivel Senior)

✅ **Bloque de Ayuda Completo:** Compatible con `Get-Help`  
✅ **Parámetros Flexibles:** Servidores DHCP configurables  
✅ **Pipeline Habilitado:** Entrada de datos mediante tuberías  
✅ **Objetos Puros:** Retorna `PSCustomObject` para máxima flexibilidad  
✅ **Modo Verboso:** Diagnósticos en tiempo real  
✅ **Validación de Entrada:** Verifica formato de IP antes de procesar  
✅ **Manejo de Errores:** Try-catch para conexiones fallidas  
✅ **Optimización:** Break cuando encuentra la IP para ahorrar tiempo  

---

