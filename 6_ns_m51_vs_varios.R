################ MALDI-TOF ANALISIS CLP ########################################
################ 6) ns_m51_vs_varios  ##########################################
#
# ns:    No Supervisado
# m51:  Utiliza las muestras (51)
# vs_varios: Utiliza los días 2 y 4 y realiza análisis vs entre CLP y SHAM
#
# Autor: Bioing. Facundo Urteaga (IBB-CONICET)
#
#
### CARGA DE LIBRERIAS #########################################################
################################################################################


library("readBrukerFlexData")
library("binda")
library("fs")
library("readxl")
library("MALDIquant")
library("MALDIquantForeign")
library("MALDIrppa")
library("tidyverse")
library("dplyr")
library("clValid")
library(cluster)
library(factoextra)


### CARGA DE ARCHIVOS ##########################################################
################################################################################


#script_path <- "C:/Users/Facundo/Documents/Proyectos/Data"
#setwd(script_path) session -> set working directory
load("matint_51_dico.Rdata")
df_metadata_unicas$dia <- as.integer(gsub("[^0-9]", "", df_metadata_unicas$dia))


### PRIMER ANÁLISIS: CLP_D2 vs CLP_D4 ##########################################
################################################################################


filas_filtradas <- rownames(matint_51_dico)[grepl("CLP_D2|CLP_D4", rownames(matint_51_dico))]
matint_51_dico_clp_d2d4 <- matint_51_dico[filas_filtradas, ]
df_unicas_clp_d2d4 <- df_metadata_unicas %>%
  dplyr::filter(factor1 == "CLP_D2" | factor1 == "CLP_D4")

# Selección de picos para binary discriminant analysis (BDA)
factor_tipo <- factor(df_unicas_clp_d2d4$factor1)
is.binaryMatrix(matint_51_dico_clp_d2d4) # TRUE
br <- binda.ranking(matint_51_dico_clp_d2d4, factor_tipo, verbose = FALSE)
indices_especificos <- br[1:20]

# Gráfico de picos vs score
nueva_columna <- c()
matriz <- matrix(br, nrow = 218, ncol = 4)
for (i in 1:218) {
  nuevo_valor <- colnames(matint_51_dico_clp_d2d4)[br[i]]
  nueva_columna<- c(nueva_columna, nuevo_valor)
}
matriz <- cbind(matriz, nueva_columna)
df_br <- data.frame(matriz)

plot(df_br$nueva_columna, df_br$V2, 
     xlab = "m/z", ylab = "Score", 
     main = "Ranking de picos de los espectros CLP_D2 vs CLP_D4")

# Crear un gradiente de colores (por ejemplo, de azul a rojo)
colores <- colorRampPalette(c("blue", "red"))(218)

# Agregar puntos con colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], col = colores[i]) 
}

# Agregar puntos con relleno de colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], pch = 19, col = colores[i]) 
}

# Selección de picos mas preponderantes
top.b10 <- br[1:10]  ## primeros 10 picos
top.b15 <- br[1:15]  ## primeros 15 picos
top.b20 <- br[1:20]  ## primeros 20 picos 
top.b30 <- br[1:30]  ## primeros 30 picos
top_actual <- top.b30 # Ir probando

# Algoritmo PAM 2 clusters con TOP15
top_actual <- top.b15
K.num <- 2 # clusters
var2 = 0.95

pam.top15.k3 <- pam(matint_51_dico_clp_d2d4[, top_actual], 
                        metric = "manhattan",
                        K.num)

cluster.pam.top15.k2 <- fviz_cluster(pam.top15.k3, ellipse.type = "convex", 
                                         data = matint_51_dico_clp_d2d4[, top_actual],
                                         ellipse.level = var2,
                                         show.clust.cent = F, 
                                         geom = "point", 
                        main = "PAM - Top 15 - 2 clusters - CLP_D2 vs CLP_D4")

# Ajustar el tamaño de los puntos según los valores de la columna "dia"
cluster.pam.top15.k2 <- cluster.pam.top15.k2 + 
  geom_point(data = cluster.pam.top15.k2$data, 
             aes(x = x, y = y, color = df_unicas_clp_d2d4$factor1, 
                 size = df_unicas_clp_d2d4$dia)) +
  scale_color_manual(values = c("maroon1","aquamarine3","maroon4","blue4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top15.k2)


### SEGUNDO ANÁLISIS: CLP_D2 vs SHAM_D2 ########################################
################################################################################


filas_filtradas <- rownames(matint_51_dico)[grepl("CLP_D2|SH_D2", rownames(matint_51_dico))]
matint_51_dico_clpd2_shamd2 <- matint_51_dico[filas_filtradas, ]
df_unicas_clpd2_shamd2 <- df_metadata_unicas %>%
  dplyr::filter(factor1 == "CLP_D2" | factor1 == "SH_D2")

# Selección de picos para binary discriminant analysis (BDA)
factor_tipo <- factor(df_unicas_clpd2_shamd2$factor1)
is.binaryMatrix(matint_51_dico_clpd2_shamd2) # TRUE
br <- binda.ranking(matint_51_dico_clpd2_shamd2, factor_tipo, verbose = FALSE)
indices_especificos <- br[1:20]

# Gráfico de picos vs score
nueva_columna <- c()
matriz <- matrix(br, nrow = 218, ncol = 4)
for (i in 1:218) {
  nuevo_valor <- colnames(matint_51_dico_clpd2_shamd2)[br[i]]
  nueva_columna<- c(nueva_columna, nuevo_valor)
}
matriz <- cbind(matriz, nueva_columna)
df_br <- data.frame(matriz)

plot(df_br$nueva_columna, df_br$V2, 
     xlab = "m/z", ylab = "Score", 
     main = "Ranking de picos de los espectros CLP_D2 vs SHAM_D2")

# Crear un gradiente de colores (por ejemplo, de azul a rojo)
colores <- colorRampPalette(c("blue", "red"))(218)

# Agregar puntos con colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], col = colores[i]) 
}

# Agregar puntos con relleno de colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], pch = 19, col = colores[i]) 
}

# Selección de picos mas preponderantes
top.b10 <- br[1:10]  ## primeros 10 picos
top.b15 <- br[1:15]  ## primeros 15 picos
top.b20 <- br[1:20]  ## primeros 20 picos 
top.b30 <- br[1:30]  ## primeros 30 picos
top_actual <- top.b30 # Ir probando

# Algoritmo PAM 2 clusters con TOP20
top_actual <- top.b20
K.num <- 2 # clusters
var2 = 0.95

pam.top20.k2 <- pam(matint_51_dico_clpd2_shamd2[, top_actual], 
                    metric = "manhattan",
                    K.num)

cluster.pam.top20.k2 <- fviz_cluster(pam.top20.k2, ellipse.type = "convex", 
                                     data = matint_51_dico_clpd2_shamd2[, top_actual],
                                     ellipse.level = var2,
                                     show.clust.cent = F, 
                                     geom = "point", 
                        main = "PAM - Top 20 - 2 clusters - CLP_D2 vs SHAM_D2 ")

# Ajustar el tamaño de los puntos según los valores de la columna "dia"
cluster.pam.top20.k2 <- cluster.pam.top20.k2 + 
  geom_point(data = cluster.pam.top20.k2$data, 
             aes(x = x, y = y, color = df_unicas_clpd2_shamd2$factor1, 
                 size = df_unicas_clpd2_shamd2$dia)) +
  scale_color_manual(values = c("maroon1","aquamarine3","maroon4","blue4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top20.k2)


### TERCER ANÁLISIS: CLP_D4 vs SHAM_D4 #########################################
################################################################################


filas_filtradas <- rownames(matint_51_dico)[grepl("CLP_D4|SH_D4", 
                                                  rownames(matint_51_dico))]
matint_51_dico_clpd4_shamd4 <- matint_51_dico[filas_filtradas, ]
df_unicas_clpd4_shamd4 <- df_metadata_unicas %>%
  dplyr::filter(factor1 == "CLP_D4" | factor1 == "SH_D4")

# Selección de picos para binary discriminant analysis (BDA)
factor_tipo <- factor(df_unicas_clpd4_shamd4$factor1)
is.binaryMatrix(matint_51_dico_clpd4_shamd4) # TRUE
br <- binda.ranking(matint_51_dico_clpd4_shamd4, factor_tipo, verbose = FALSE)
indices_especificos <- br[1:20]

# Gráfico de picos vs score
nueva_columna <- c()
matriz <- matrix(br, nrow = 218, ncol = 4)
for (i in 1:218) {
  nuevo_valor <- colnames(matint_51_dico_clpd4_shamd4)[br[i]]
  nueva_columna<- c(nueva_columna, nuevo_valor)
}
matriz <- cbind(matriz, nueva_columna)
df_br <- data.frame(matriz)

plot(df_br$nueva_columna, df_br$V2, 
     xlab = "m/z", ylab = "Score", 
     main = "Ranking de picos de los espectros CLP_D4 vs SHAM_D4")

# Crear un gradiente de colores (por ejemplo, de azul a rojo)
colores <- colorRampPalette(c("blue", "red"))(218)

# Agregar puntos con colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], col = colores[i]) 
}

# Agregar puntos con relleno de colores en forma de gradiente
for (i in 1:218) {
  points(df_br$nueva_columna[i], df_br$V2[i], pch = 19, col = colores[i]) 
}

# Selección de picos mas preponderantes
top.b10 <- br[1:10]  ## primeros 10 picos
top.b15 <- br[1:15]  ## primeros 15 picos
top.b20 <- br[1:20]  ## primeros 20 picos 
top.b30 <- br[1:30]  ## primeros 30 picos
top_actual <- top.b30 # Ir probando

# Algoritmo PAM 2 clusters con TOP20
top_actual <- top.b20
K.num <- 2 # clusters
var2 = 0.95

pam.top15.k2 <- pam(matint_51_dico_clpd4_shamd4[, top_actual],
                        metric = "manhattan",
                        K.num)

cluster.pam.top15.k2 <- fviz_cluster(pam.top15.k2, 
                                         ellipse.type = "convex", 
                                         data = matint_51_dico_clpd4_shamd4[, top_actual],
                                         ellipse.level = var2,
                                         show.clust.cent = F, 
                                         geom = "point",
                            main = "PAM - Top 15 - 2 clusters - CLP_D4 vs SHAM_D4 ")

cluster.pam.top15.k2 <- cluster.pam.top15.k2 + 
  geom_point(data = cluster.pam.top15.k2$data, 
             aes(x = x, y = y, color = df_unicas_clpd4_shamd4$factor1,
                 size = df_unicas_clpd4_shamd4$dia)) +
  scale_color_manual(values = c("maroon1","aquamarine3","maroon4","blue4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top15.k2)

#
#
#
### FIN ########################################################################
################################################################################