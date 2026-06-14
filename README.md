# **DHCP Lease Searcher** 🔍

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Platform](https://img.shields.io/badge/Platform-Windows_Server|Windows_10/11-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## 📌 **Descripción General**

Herramienta avanzada de **PowerShell** diseñada para administradores de red y sistemas que necesitan **buscar de forma centralizada** direcciones IP v4 en múltiples servidores DHCP de **Microsoft Windows Server**.

Automatiza la consulta de reservas y concesiones de IPs, eliminando la necesidad de acceder manualmente a cada consola de DHCP. Ideal para **auditorías rápidas, resolución de problemas de conectividad o generación de reportes de infraestructura**.

---

## 🚀 **Características Clave**

✅ **Búsqueda Multi-Servidor**
Consulta de forma **secuencial y optimizada** en múltiples servidores DHCP configurados.

✅ **Procesamiento en Lote (Batch)**
Permite buscar **una o múltiples direcciones IP** en una sola ejecución.

✅ **Integración con Pipeline**
Totalmente compatible con la tubería (`|`) de PowerShell para:
- Entrada dinámica de IPs.
- Salida estructurada para exportación (CSV, JSON, GridView).

✅ **Orientado a Objetos**
Retorna objetos puros de tipo `[PSCustomObject]`, facilitando:
- Filtrado avanzado (`Where-Object`).
- Exportación a formatos estándar.
- Integración con herramientas externas.

✅ **Modo Silencioso/Verboso**
- **`-Verbose`**: Muestra el progreso en tiempo real (útil para depuración).
- **`-ErrorAction SilentlyContinue`**: Evita mensajes innecesarios si una IP no existe.

✅ **Validación de Formato IP**
Opcionalmente valida el formato de las IPs ingresadas antes de realizar la búsqueda.

---

## 📋 **Requisitos Previos**

Para ejecutar el script correctamente, asegúrate de que tu entorno cumpla con:

| Requisito | Detalles |
|-----------|----------|
| **PowerShell** | Versión **5.1+** (incluyendo PowerShell 7+). |
| **Módulo DHCP** | Debe estar instalado el módulo oficial de administración de DHCP (`DhcpServer`). |
| **Permisos** | Ejecutar PowerShell como **Administrador** y tener permisos de **lectura** en los servidores DHCP de destino. |
| **Política de Ejecución** | Configurar la política de ejecución si es necesario: <br> ```powershell<br>Set-ExecutionPolicy RemoteSigned -Scope CurrentUser<br>``` |

### 🔧 **Instalación del Módulo DHCP**
#### **En Windows Server:**
```powershell
Install-WindowsFeature RSAT-DHCP -IncludeManagementTools
```
#### **En Windows 10/11 (con RSAT):**
1. Abre **Panel de Control** > **Programas** > **Activar o desactivar características de Windows**.
2. Selecciona **Herramientas de administración remota del servidor** > **Herramientas de rol de DHCP**.
3. Haz clic en **Aceptar** y reinicia si es necesario.

---

## 🔧 **Parámetros del Script**

El script acepta los siguientes parámetros personalizables:

| Parámetro | Tipo | Obligatorio | Posición | Descripción |
|-----------|------|-------------|----------|-------------|
| `-IPAddress` | `String[]` | **Sí** | 0 | Una o más direcciones IP v4 que se desean buscar. Ejemplo: `"192.168.1.50", "10.0.0.25"`. |
| `-DhcpServers` | `String[]` | No | 1 | Arreglo de **nombres de host o IPs** de los servidores DHCP. Si no se especifica, usa los servidores por defecto configurados en el script. |
| `-Verbose` | `Switch` | No | - | Muestra información detallada durante la ejecución (útil para depuración). |

---

## 💻 **Ejemplos de Uso**

### **1. Búsqueda Básica de una Sola IP**
Busca una IP específica utilizando los servidores configurados por defecto.
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50"
```

### **2. Búsqueda de Múltiples IPs en Servidores Específicos**
Sobrescribe los servidores por defecto y busca una lista de IPs.
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50", "10.0.0.25" -DhcpServers "DHCP-PROD-01", "DHCP-PROD-02"
```

### **3. Uso con Entrada de Pipeline e Interfaz Gráfica**
Pasa una lista de IPs desde la tubería y despliega el resultado en una ventana interactiva.
```powershell
"192.168.1.50", "10.0.0.25", "172.16.5.11" | .\Get-DhcpLeaseSearch.ps1 | Out-GridView
```

### **4. Auditoría y Exportación a CSV**
Genera un reporte mensual de infraestructura.
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress (Get-Content .\lista_ips.txt) | Export-Csv -Path ".\Resultado_DHCP.csv" -NoTypeInformation
```

### **5. Diagnóstico Técnico (Modo Verboso)**
Visualiza en tiempo real qué servidor está siendo consultado.
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50" -Verbose
```

### **6. Búsqueda con Validación de Formato IP**
Omite IPs con formato incorrecto automáticamente.
```powershell
.\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50", "192.168.1", "10.0.0.25"
# Muestra advertencia: "El formato de la IP '192.168.1' no es válido. Se omitirá."
```

---

## 📊 **Estructura del Objeto de Salida**

Cada consulta genera una salida estandarizada con las siguientes propiedades:

| Propiedad | Tipo | Descripción |
|-----------|------|-------------|
| **IPAddress** | `String` | Dirección IP consultada. |
| **ScopeId** | `String` | ID del ámbito (subred) al que pertenece la IP. |
| **ClientId** | `String` | Dirección MAC del dispositivo (si está asignada). |
| **Name** | `String` | Nombre del dispositivo o descripción de la reserva. |
| **DhcpServer** | `String` | Servidor DHCP donde se encontró la coincidencia. |
| **Status** | `String` | Estado del resultado (`"Encontrado"` o `"No Encontrado"`). |

### **Ejemplo de Salida**
```powershell
IPAddress      : 192.168.1.50
ScopeId        : 192.168.1.0
ClientId       : 00-1A-2B-3C-4D-5E
Name           : Laptop-Contabilidad
DhcpServer     : DHCP-PROD-01
Status         : Encontrado
```

---

## 🛠️ **Configuración Inicial**

### **1. Personalizar Servidores DHCP por Defecto**
Abre el archivo `Get-DhcpLeaseSearch.ps1` y modifica la línea:
```powershell
[Parameter(Mandatory = $false)]
[String[]]$DhcpServers = @("TU_SERVIDOR_1", "TU_SERVIDOR_2") # Ejemplo: @("DHCP-PROD-01", "DHCP-PROD-02")
```

### **2. Configurar Política de Ejecución (Opcional)**
Si recibes errores de ejecución:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📜 **Código del Script (`Get-DhcpLeaseSearch.ps1`)**

```powershell
<#
.SYNOPSIS
    Busca reservas y concesiones de IP en múltiples servidores DHCP.
.DESCRIPTION
    Este script recorre una lista de servidores DHCP buscando una o más direcciones IP
    y devuelve un objeto personalizado con los resultados.
.EXAMPLE
    .\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50", "10.0.0.25"
.NOTES
    Autor: [Tu Nombre]
    Versión: 1.0
    Licencia: MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String[]]$IPAddress,

    [Parameter(Mandatory = $false)]
    [String[]]$DhcpServers = @("SERVER1", "SERVER2") # Modifica por tus servidores
)

PROCESS {
    foreach ($CurrentIP in $IPAddress) {
        # Validación de formato IP (opcional)
        if ($CurrentIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            Write-Warning "El formato de la IP '$CurrentIP' no es válido. Se omitirá."
            continue
        }

        Write-Verbose "Buscando la dirección IP: $CurrentIP..."
        $FoundInAnyServer = $false

        foreach ($DhcpServer in $DhcpServers) {
            Write-Verbose "Consultando servidor: $DhcpServer"

            try {
                $Result = Get-DhcpServerv4Reservation -ComputerName $DhcpServer -IPAddress $CurrentIP -ErrorAction SilentlyContinue

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
                    break # Optimización: detiene la búsqueda en el primer servidor que encuentre la IP
                }
            }
            catch {
                Write-Error "Error al conectar con el servidor DHCP $DhcpServer : $_"
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

## 📝 **Notas Adicionales**

### ⚠️ **Consideraciones Importantes**
- **Permisos:** Asegúrate de que tu cuenta tenga permisos de **lectura** en los servidores DHCP.
- **Firewall:** Verifica que el firewall permita la comunicación entre tu máquina y los servidores DHCP (puerto **TCP 445** para SMB/RPC).
- **Rendimiento:** Para búsquedas en grandes listas de IPs, considera ejecutar el script en horarios de baja demanda.

### 🔄 **Mejoras Futuras**
- **Soporte para IPv6** (si se implementa en tu infraestructura).
- **Caché de resultados** para evitar consultas repetidas en el mismo servidor.
- **Integración con Active Directory** para validar permisos automáticamente.

---

## 📜 **Licencia**

Este proyecto se distribuye bajo la **Licencia MIT**. Consulta el archivo `LICENSE` para más detalles.

```text
Copyright (c) [2026] [kaleth]

Permiso se otorga, sin cargo, a cualquier persona que obtenga una copia
de este software y los archivos de documentación asociados (el DHCP Lease Searcher),
para tratar el Software sin restricción, incluyendo sin limitación los derechos
a usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender
copias del Software, y permitir a las personas a quienes se les proporcione el
Software a hacer lo mismo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en todas
las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O
IMPLÍCITA, INCLUIDAS PERO NO LIMITADAS A LAS GARANTÍAS DE COMERCIALIZACIÓN,
IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS
AUTORES O TITULARES DE LOS DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGUNA
RECLAMACIÓN, DAÑOS U OTRAS RESPONSABILIDADES, YA SEA EN UNA ACCIÓN DE CONTRATO,
RESPONSABILIDAD EXTRACONTRACTUAL O DE OTRO TIPO, DERIVADAS DE O EN CONEXIÓN
CON EL SOFTWARE O EL USO U OTRO TIPO DE ACCIONES EN EL SOFTWARE.
```



