#RUTA DE LA CARPETA DONDE SE DESCARGARAN LOS ACHIVOS. CARPETA GML EN EL ESCRITORIO.
$carpetadescarga = "$env:HOMEPATH\Desktop\GML"

#ESPECIFICA LA VISIBILIDAD DE LOS MENSAJES DE DEBUG
$DebugPreference = "Continue"

#LISTADO DE PARAMETROS DEL SERVIDOR WFS. CAPA. CAMPO PARA AGRUPACION DE DATOS. CAMPOS DESCARGADOS. URL BASE DEL SERVIDOR WFS.
@(
[pscustomobject]@{capa="municipios";camponombre= "NOMBRE";campos = "NOMBRE,msGeometry";URLWFS="https://ogc.larioja.org/wfs/callejerodelarioja/request.php?"}
[pscustomobject]@{capa="viales";camponombre= "NOMBRE_MUNICIPIO";campos = "NOMBRE_COMPLETO_VIAL,NOMBRE_POBLAMIENTO,msGeometry";URLWFS="https://ogc.larioja.org/wfs/callejerodelarioja/request.php?"}
[pscustomobject]@{capa="portales";camponombre= "NOMBRE_MUNICIPIO";campos = "NOMBRE_COMPLETO_VIAL,NUMERO_POLICIA,EXTENSION,CODIGO_POSTAL,NOMBRE_POBLAMIENTO,msGeometry";URLWFS="https://ogc.larioja.org/wfs/callejerodelarioja/request.php?"}
[pscustomobject]@{capa="poblaciones";camponombre= "T108_000_MUNICIPIOS_DENO";campos = "T108_000_NUCL_URB_DENO,msGeometry";URLWFS="https://ogc.larioja.org/wfs/callejerodelarioja/request.php?"}
[pscustomobject]@{capa="edificios";camponombre= "T223_000_INEMUNICIPIO_DENO";campos = "T223_000_INEMUNICIPIO_DENO,msGeometry";URLWFS="https://ogc.larioja.org/wfs/callejerodelarioja/request.php?"}
    ) | ForEach-Object {
            #ASIGNACION DE OBJETO EN CURSO PARA SU TRATAMIENTO
            $capa= $_.capa
            $camponombre=$_.camponombre
            $campos=$_.campos
            $URLWFS=$_.URLWFS
            Write-Debug "Descargando lista de elementos $camponombre en capa $capa"
            #DESCARGA DE TODOS LOS ELEMENTOS DE LA CAPA UNICOS DE LA CAPA.
            ([XML]((Invoke-WebRequest "$($URLWFS)service=wfs&version=1.1.0&request=getfeature&typename=$($capa)&srsname=EPSG:4326&pagingEnabled=false&format-options=XMLSCHEMA&propertyName=$($camponombre)" -UseBasicParsing).content)).FeatureCollection.featureMember.$CAPA.$CAMPONOMBRE | Sort-Object | Get-Unique | ForEach-Object {
                #CREACION DE LA CARPETA SI NO EXISTE.
                if(!(Test-Path $carpetadescarga\$($_))){Write-debug "NO EXISTE CARPETA. CREANDO CARPETA $carpetadescarga\$($_)";New-Item -Path $carpetadescarga\$($_) -ItemType Directory|Out-Null}
                if(!(test-path $carpetadescarga\$($_)\$($_)-$($capa).gml)){
                    #DESCARGA DE LOS DATOS SI NO EXISTEN.
                    Write-Debug "Descargando campos $campos de capa $capa de $camponombre = $_"
                    (Invoke-WebRequest $("$($URLWFS)service=wfs&version=1.1.0&request=getfeature&typename=$($capa)&srsname=EPSG:4326&pagingEnabled=false&format-options=XMLSCHEMA&FILTER=<Filter><PropertyIsEqualTo><PropertyName>$($CAMPONOMBRE)</PropertyName> <Literal>$($_)</Literal></PropertyIsEqualTo></Filter>&propertyName=$($campos)") -UseBasicParsing).content| set-content $carpetadescarga\$($_)\$($_)-$($capa).gml -Encoding UTF8
                        if(test-path $carpetadescarga\$($_)\$($_)-$($capa).gml){
                        #CORRECCION EJES DE COORDENADAS
                        Write-Debug "TENGA PACIENCIA. INTERCAMBIANDO EJE DE COORDENADAS DE LONGITUD,LATITUD A LATITUD,LONGITUD EN $carpetadescarga\$($_)\$($_)-$($capa).gml ..."
                        [string]$GML = Get-Content $carpetadescarga\$($_)\$($_)-$($capa).gml -Raw -Encoding UTF8
                        ((Get-Content $carpetadescarga\$($_)\$($_)-$($capa).gml -Raw | Select-String -AllMatches "-?([1-8]?[1-9]|[1-9]0)\.{1}\d{1,6} -?([1-8]?[1-9]|[1-9]0)\.{1}\d{1,6}").Matches.value) | Sort-Object | Get-Unique | ForEach-Object {
                            #PASO DE SUSTITUICION INTERMEDIA PARA EVITAR INTERCAMBIOS DE COORDENADAS INCORRECTOS. LAS COORDENADAS GML NO ESTAN SEPARADAS ENTRE SI CON NADA PARA DIFERENCIARLAS UNAS DE OTRAS.
                            [string]$sustituido = $_;[string]$sustituto = $_.Split("")[1]+"ÑÑÑ"+$_.Split("")[0]+"ÑÑÑ"
                            $GML = $GML.Replace("$sustituido","$sustituto")
                            }
                        $gml = $GML.Replace("ÑÑÑ"," ") | Set-Content $carpetadescarga\$($_)\$($_)-$($capa)-LATLON.gml -Encoding UTF8
                        Remove-Item $carpetadescarga\$($_)\$($_)-$($capa).gml -Force -Confirm:$false
                        }
                    }
            }
        }