################ MALDI-TOF ANALISIS CLP ########################################
################ 4) ns_m122_d24  ###############################################
#
# ns:    No Supervisado
# m122:  Utiliza las wells (122 muestras)
# d1247: Utiliza los días 2 y 4
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
load("matint_122_dico.Rdata")
load("matint_122.Rdata")


df_metadata_prom_rep$dia <- as.integer(gsub("[^0-9]", "", 
                                            df_metadata_prom_rep$dia))

# Filtrado de muestras de día 2 y día 4
filas_filtradas <- rownames(matint_122_dico)[grepl("D2|D4", rownames(matint_122_dico))]
matint_122_dico_d2d4 <- matint_122_dico[filas_filtradas, ]
filas_filtradas <- rownames(matint_122)[grepl("D2|D4", rownames(matint_122))]
matint_122_d2d4 <- matint_122[filas_filtradas, ]

df_prom_rep_d2d4 <- df_metadata_prom_rep %>% dplyr::filter(dia == 2 | dia == 4)


### SELECCIÓN DE PICOS #########################################################
################################################################################


# Selección de picos para binary discriminant analysis (BDA)

factor_tipo <- factor(df_prom_rep_d2d4$factor1)
is.binaryMatrix(matint_122_dico_d2d4) # TRUE
br <- binda.ranking(matint_122_dico_d2d4, factor_tipo, verbose = FALSE)
indices_especificos <- br[1:20]

# Gráfico de picos vs score 
nueva_columna <- c()
matriz <- matrix(br, nrow = 218, ncol = 4)
for (i in 1:218) {
  nuevo_valor <- colnames(matint_122_dico_d2d4)[br[i]]
  nueva_columna<- c(nueva_columna, nuevo_valor)
}
matriz <- cbind(matriz, nueva_columna)
df_br <- data.frame(matriz)

plot(df_br$nueva_columna, df_br$V2, 
     xlab = "m/z", ylab = "Score", 
     main = "Ranking de picos de los espectros, 4 clusters")
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
top_actual <- top.b30

# Elección de mejores algoritmos de clustering
comparacion <- clValid(
  obj        = matint_122_dico_d2d4[, top_actual],
  nClust     = 2:6,
  clMethods  = c("hierarchical", "kmeans", "pam"),
  validation = c("stability", "internal")
)

summary(comparacion)
optimalScores(comparacion) # Se puede ir probando con distintos top picos


### ALGORITMOS DE CLUSTERING ###################################################
################################################################################


# Con top30: HIERARCHICAL KMEANS clustering 2 clusters
top_actual <- top.b30
K.num <- 2 # clusters
var2 = 0.95

hkmeans.top30.k2 <- hkmeans(matint_122_dico_d2d4[, top_actual], 
                      K.num)

cluster.hkmeans.top30.k2 <- fviz_cluster(
                                  hkmeans.top30.k2, 
                                  ellipse.type = "convex", 
                                  data = matint_122_dico_d2d4[, top_actual],
                                  ellipse.level = var2,
                                  show.clust.cent = F, 
                                  geom = "point", 
                                  main = "hkmeans - Top 30 - 2 clusters")

cluster.hkmeans.top30.k2 <- cluster.hkmeans.top30.k2 + 
  geom_point(data = cluster.hkmeans.top30.k2$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1, 
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","maroon1", "maroon4", 
                                               "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +  
  theme(legend.position = "right")

print(cluster.hkmeans.top30.k2)

# Con top20: PAM clustering 3 clusters
top_actual <- top.b20
K.num <- 3 # clusters
var2 = 0.95

pam.top20.k3 <- pam(x= matint_122_dico_d2d4[, top_actual], K.num, 
                    metric = "manhattan")

cluster.pam.top20.k3 <- fviz_cluster(pam.top20.k3, ellipse.type = "convex", 
                                data = matint_122_dico_d2d4[, top_actual],
                                ellipse.level = var2,
                                show.clust.cent = F, 
                                geom = "point", 
                                main = "PAM - Top 20 - 3 cluster")


cluster.pam.top20.k3 <- cluster.pam.top20.k3 + 
  geom_point(data = cluster.pam.top20.k3$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1, 
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","blue4","maroon1", 
                                "maroon4", "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) +  
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top20.k3)

# Con top20: PAM clustering 2 clusters
top_actual <- top.b20
K.num <- 2 # clusters
var2 = 0.95

pam.top20.k2 <- pam(x= matint_122_dico_d2d4[, top_actual], K.num, 
                    metric = "manhattan")

cluster.pam.top20.k2 <- fviz_cluster(pam.top20.k2, ellipse.type = "convex", 
                              data = matint_122_dico_d2d4[, top_actual],
                              ellipse.level = var2,
                              show.clust.cent = F, 
                              geom = "point", main = "PAM - Top 20 - 2 cluster")

cluster.pam.top20.k2 <- cluster.pam.top20.k2 + 
  geom_point(data = cluster.pam.top20.k2$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1, 
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","maroon1", "maroon4",
                                "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) +  
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top20.k2)

# Con top15: KMEAN CLUSTERING 2 clusters

top_actual <- top.b15
K.num <- 2 # clusters
var2 = 0.95

kmeans.top15.k2 <- kmeans(matint_122_dico_d2d4[, top_actual], 
                    K.num, nstart = 25)

cluster.kmeans.top15.k2 <- fviz_cluster(kmeans.top15.k2, 
                                        ellipse.type = "convex", 
                                data = matint_122_dico_d2d4[, top_actual],
                                ellipse.level = var2,
                                show.clust.cent = F, 
                                geom = "point", 
                                main = "KMEANS - Top 15 - 2 cluster")

cluster.kmeans.top15.k2 <- cluster.kmeans.top15.k2 + 
  geom_point(data = cluster.kmeans.top15.k2$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1,
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","maroon1", "maroon4",
                                "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) +  
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.kmeans.top15.k2)

# Con top10: KMEAN CLUSTERING 2 clusters
top_actual <- top.b10
K.num <- 2 # clusters
var2 = 0.95

kmeans.top10.k2 <- kmeans(matint_122_dico_d2d4[, top_actual], 
                    K.num, nstart = 25)

cluster.kmeans.top10.k2 <- fviz_cluster(kmeans.top10.k2, 
                                        ellipse.type = "convex", 
                                data = matint_122_dico_d2d4[, top_actual],
                                ellipse.level = var2,
                                show.clust.cent = F, 
                                geom = "point", 
                                main = "KMEANS - Top 10 - 2 cluster")

cluster.kmeans.top10.k2 <- cluster.kmeans.top10.k2 + 
  geom_point(data = cluster.kmeans.top10.k2$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1,
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","maroon1", "maroon4",
                                "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) + 
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.kmeans.top10.k2)

# Con top10: PAM CLUSTERING 2 clusters
top_actual <- top.b10
K.num <- 2 # clusters
var2 = 0.95

pam.top10.k2 <- pam(x= matint_122_dico_d2d4[, top_actual], K.num, 
                    metric = "manhattan")

cluster.pam.top10.k2 <- fviz_cluster(pam.top10.k2, ellipse.type = "convex", 
                              data = matint_122_dico_d2d4[, top_actual],
                              ellipse.level = var2,
                              show.clust.cent = F, 
                              geom = "point", 
                              main = "PAM - Top 10 - 2 cluster")

cluster.pam.top10.k2 <- cluster.pam.top10.k2 + 
  geom_point(data = cluster.pam.top10.k2$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1, 
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("blueviolet","aquamarine3","maroon1", "maroon4",
                                "blue1","blue4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

print(cluster.pam.top10.k2)


### PRUEBA 3 GRUPOS: SH(D2 Y D4) VS CLP_D4 VS CLP_D2 ###########################
################################################################################

# Agrupo factor SH
df_prom_rep_d2d4 <- df_prom_rep_d2d4 %>%
  mutate(factor1 = ifelse(grepl("SH", factor1), "SH", factor1)) 

# Selección de picos para binary discriminant analysis (BDA)
factor_tipo <- factor(df_prom_rep_d2d4$factor1)
is.binaryMatrix(matint_122_dico_d2d4) # TRUE
br <- binda.ranking(matint_122_dico_d2d4, factor_tipo, verbose = FALSE)
indices_especificos <- br[1:20]

# Gráfico de picos vs score
nueva_columna <- c()
matriz <- matrix(br, nrow = 218, ncol = 4)
for (i in 1:218) {
  nuevo_valor <- colnames(matint_122_dico_d2d4)[br[i]]
  nueva_columna<- c(nueva_columna, nuevo_valor)
}
matriz <- cbind(matriz, nueva_columna)
df_br <- data.frame(matriz)

plot(df_br$nueva_columna, df_br$V2, 
     xlab = "m/z", ylab = "Score", 
     main = "Ranking de picos de los espectros, 3 clusters")

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

# Selección de picos
top.b10 <- br[1:10]  ## primeros 10 picos
top.b15 <- br[1:15]  ## primeros 15 picos
top.b20 <- br[1:20]  ## primeros 20 picos 
top.b30 <- br[1:30]  ## primeros 30 picos
top.b40 <- br[1:40]  ## primeros 30 picos
top_actual <- top.b10 # Ir probando

# Elección del mejor algoritmo de clustering
comparacion <- clValid(
  obj        = matint_122_dico_d2d4[, top_actual],
  nClust     = 2:6,
  clMethods  = c("hierarchical", "kmeans", "pam"),
  validation = c("stability", "internal")
)

summary(comparacion)
optimalScores(comparacion)


# Con top30: PAM CLUSTERING 3 clusters
top_actual <- top.b30
K.num <- 3 # clusters
var2 = 0.95

pam.top30.k4.g3 <- pam(matint_122_dico_d2d4[, top_actual], metric = "euclidean",
                          K.num)

cluster.pam.top30.k4.g3 <- fviz_cluster(pam.top30.k4.g3, 
                                        ellipse.type = "convex", 
                                        data = matint_122_dico_d2d4[, top_actual],
                                        ellipse.level = var2,
                                        show.clust.cent = F,
                                        geom = "point", 
                                        main = "PAM - Top 30 - 3 cluster")

# Ajustar el tamaño de los puntos según los valores de la columna "dia"
cluster.pam.top30.k4.g3 <- cluster.pam.top30.k4.g3 + 
  geom_point(data = cluster.pam.top30.k4.g3$data, 
             aes(x = x, y = y, color = df_prom_rep_d2d4$factor1,
                 size = df_prom_rep_d2d4$dia)) +
  scale_color_manual(values = c("maroon1","aquamarine3","blueviolet","blue1",
                                "blue4", "maroon4")) +
  scale_size_continuous(range = c(2, 3)) +
  labs(color = "Cluster", size = "Día") +
  theme(legend.position = "right")

# Muestra el gráfico
print(cluster.pam.top30.k4.g3)


### EXPORTAR MATRICES CON 30 PICOS DE INTERÉS ##################################
################################################################################



write.csv(matint_122_dico_d2d4[, top_actual], "top30_107_dico_d24.csv",
          row.names = TRUE)
write.csv(matint_122_d2d4[, top_actual], "top30_107_d24.csv", row.names = TRUE)
write.csv(df_prom_rep_d2d4, "metadata_107.csv", row.names = TRUE)
#
#
#
### FIN ########################################################################
################################################################################
