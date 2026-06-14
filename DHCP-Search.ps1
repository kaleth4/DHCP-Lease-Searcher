<#
.SYNOPSIS
    Busca reservas y concesiones de IP en múltiples servidores DHCP.
.DESCRIPTION
    Este script recorre una lista de servidores DHCP buscando una o más direcciones IP
    y devuelve un objeto personalizado con los resultados.
.EXAMPLE
    .\Get-DhcpLeaseSearch.ps1 -IPAddress "192.168.1.50", "10.0.0.25"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String[]]$IPAddress,

    [Parameter(Mandatory = $false)]
    [String[]]$DhcpServers = @("SERVER1", "SERVER2") # Centralizado como parámetro modificable
)

PROCESS {
    # Bucle para procesar cada IP solicitada
    foreach ($CurrentIP in $IPAddress) {
        
        # Validación básica de formato IP (Opcional pero recomendado)
        if ($CurrentIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            Write-Warning "El formato de la IP '$CurrentIP' no es válido. Se omitirá."
            continue
        }

        Write-Verbose "Buscando la dirección IP: $CurrentIP..."
        $FoundInAnyServer = $false

        # Bucle para recorrer los servidores DHCP
        foreach ($DhcpServer in $DhcpServers) {
            Write-Verbose "Consultando servidor: $DhcpServer"
            
            try {
                $Result = Get-DhcpServerv4Reservation -ComputerName $DhcpServer -IPAddress $CurrentIP -ErrorAction SilentlyContinue
                
                if ($Result) {
                    $FoundInAnyServer = $true
                    # Retorna un objeto puro. Sin Format-Table para preservar los datos.
                    [PSCustomObject]@{
                        IPAddress  = $Result.IPAddress
                        ScopeId    = $Result.ScopeId
                        ClientId   = $Result.ClientId
                        Name       = $Result.Name
                        DhcpServer = $DhcpServer
                        Status     = "Encontrado"
                    }
                    break # Si la encuentra en un servidor, rompe el bucle de servidores (optimiza tiempo)
                }
            }
            catch {
                Write-Error "Error al conectar con el servidor DHCP $DhcpServer : $_"
            }
        }

        # Si terminó de buscar en todos los servidores y no se encontró
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
