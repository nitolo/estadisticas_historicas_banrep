##################################################
###### CODIGO DE UNION DE BD DE BANREP ###########
##################################################

# no colocar ni tildes ni caracteres especiales

rm(list = ls()) # limpiar objetos
graphics.off() # borrar las graficas actuales
clc <- function() cat("\014") # borrar todo en el ambiente
clc() # borrar todo en consola
 ##################################################
############## LLAMAR LIBRERIAS ##################
##################################################
library(data.table) # leer tablas rapido, sobre todo csv
library(tidyverse) # manejo de datos
library(lubridate) # manejo de fechas
library(fixest) # regresiones con correcion de errores y paneles
library(openxlsx) # para exportar tablas a Excel en xlsx
library(readxl) # para importar archivos xlsx
library(janitor) # para limpieza de nombres de columnas
library(stringr) # manipulacion de caracteres
library(purrr) # realizar bucles
library(haven) # exportar a stata
library(sjlabelled) # etiquetar datos
library(labelled) # etiqeutar datos

##################################################
########## ESTABLECER ESCRITORIO #################
##################################################

setwd("C:/Users/user/Documents/Trabajo/Ricardo/BanRep")

##################################################
########## LLAMAR BASES DE DATOS #################
##################################################

# 1. Ver el listado de archivos .xlsx presentes en 
#    el directorio que estoy trabajando

archivos <- list.files(pattern = '*.xlsx') 
archivos

# 2. Ejecutar un loop que trae todos los archivos presentes
#    esto con el fin de evitar subirlo uno a uno
for (nombre_archivo in archivos) {
  # Extraemos el nombre antes del .xlsx
  nombre_objeto <- sub("\\.xlsx$", "", nombre_archivo)
  
  # Cargamos la hoja "Series de datos" de cada archivo
  datos <- read_excel(nombre_archivo, sheet = "Series de datos")
  
  # Limpiamos los nombres de las columnas
  datos <- clean_names(datos) # e.g, Inflación - (IPC) va a quedar
  # inflacion_ipc
  
  # Obtenemos los nombres de todas las columnas excepto "date"
  columnas <- colnames(datos)[colnames(datos) != "date"]
  
  # Aplicamos la limpieza a todas las columnas excepto "date"
  for (columna in columnas) {
    # Limpiamos los datos que vienen con . en los espacios vacios
    datos[[columna]][datos[[columna]] == '.'] <- NA
    
    # Luego, convertimos la columna a numeric, ya que quedan tipo chr
    datos[[columna]] <- as.numeric(datos[[columna]])
  }
  # Comprobamos si la columna "date" es de tipo chr (hay algunos que)
  # no les toma el formato fecha desde el principio
  if (is.character(datos$date)) {
    # Convertimos la columna "date" a tipo dttm
    datos$date <- as.Date(datos$date, format = "%d/%m/%Y")
  }
    # Asignamos el data frame limpio al objeto con el nombre adecuado
  assign(nombre_objeto, datos) # es decir, se van a llamar como aparecen
  # en excel, y no por un nombre generico
}

##################################################
############ UNIR BASES DE DATOS #################
##################################################

# 1. Utilizar una base de datos llave, que tiene la fecha desde
#    1905 hasta 2024

fechas <- rbind(fechas_1905_1918, fechas_1919_2024)
glimpse(fechas)

# 2. Sacar en una lista los nombres de los objetos 
#    activos en este momento. La anterior base de datos va a ser la inicial

datos_activos <- list(fechas
                      # 1. Mercado laboral
                      , salario_minimo
                      , tasa_ocupacion_desempleo
                      # 2. Precios e inflacion
                        # 2.1 IPC
                      , inflaciones_basicas
                      , inflacion_ciudad
                      , inflacion_ingresos
                      , ipc_total
                      , medidas_inflacion
                      , meta_inflacion
                        # 2.2 IPP
                      , ipp_actividad_economica
                      , ipp_procedencia_bienes
                      , ipp_destino_economico
                      , ipp_total
                        # 2.3 UVR
                      , uvr
                        # 2.4 Vivienda
                      , vivienda
                      # 3. PIB
                      , pib_demanda
                      , pib_grandes_ramas
                      , pib_1905
                      # 4. Tasa de cambio y sector externo
                        # 4.1 Tasa de cambio
                      , itcr
                      , tasa_cambio_nominal
                        # 4.2 Terminos de intercambio
                      , iti_ipp
                      , iti_m_x
                        # 4.3 Remesas
                      , remesas
                        # 4.4 Posicion inversion internacional
                      , posicion_inversion_internacional
                      , posicion_inversion_internacional_porcentaje_pib
                        # 4.5 Cuenta corriente (%PIB)
                      , cuenta_corriente_porcentaje_pib
                        # 4.6 Comercio exterior
                      , balanza_comercial_bienes
                      , exportaciones_por_producto
                      , importaciones_cuode
                        # 4.7 Balanza de pagos
                      , bop_46_69
                      , bop_70_93
                      , bop_94_99
                      , bop_00_23
                        # 4.8 Balanza cambiaria
                      , balanza_cambiaria
                      , cuentas_compensacion
                        # 4.9 Deuda externa
                      , flujos_71_23
                      , saldos_71_23
                      , saldo_porcentaje_pib_71_23
                        # 4.10 Inversion extranjera directa (IED)
                          # 4.10.1 Inversion directa de Colombia en el exterior
                      , idce_actividad_economica_trimestral
                      , idce_pais_destino_94_23
                      , idce_total_70_23
                          # 4.10.2 IED  
                      , ied_actividad_economica_trimestral
                      , ied_pais_origen_94_23
                      , ied_total_70_23
                          
                      )

# 3. Es hacer un left_join, pero sin tener que repetirlo multiples veces
data_final  <- reduce(datos_activos, left_join, by = "date")
glimpse(data_final)

##################################################
########## EXPORTAR BASE DE DATOS ################
##################################################

# 4. Exportar los archivos a múltiples formatos
#fwrite(data_final, "datos_banrep.csv") # en formato csv
#write.xlsx(data_final, "datos_banrep.xlsx") # en formato Excel

# 5. Ahora con los datos etiquetados

# 5.1 Vamos a crear una secuencia de pseudo nombres para cambiar
# el nombre actual de las columnas que son muy largos

nombres_nuevos <- paste("banrep_" # la etiqueta que van a tener todas las columnas
                 , 1:577 # el # de columnas que tiene el archivo fina, 
                         # sin contar la primera fila
                 , sep = "" # sin espacios
                 )
nombres_nuevos

# 5.2 Extraemos los nombres actuales

nombres_actuales <- colnames(data_final)
etiquetas <- colnames(data_final)

# 5.3 Reemplazamos los viejos por los nuevos
nombres_actuales[2:length(nombres_actuales)] <- nombres_nuevos

# 5.4 Se los colocamos a la base
colnames(data_final) <- nombres_actuales

glimpse(data_final)
# prueba2 <- data_final
data_final_stata <- set_label(data_final,etiquetas
                      )
view(data_final_stata)

# 5.5 Exportamos a formato tipo .dta con etiquetas
write_dta(data_final_stata, "datos_banrep.dta") # en formato Stata

# 5.6 Exportamos los nombres de las etiquetas
metadato <- data.frame(nombres_actuales, etiquetas)
write.xlsx(metadato, "metadato_stata.xlsx")
